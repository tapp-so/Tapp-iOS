import Foundation
import TappNetworking

@objc
public class Tapp: NSObject {

    public static var instance: Tapp {
        return single
    }

    static let single: Tapp = .init()

    init(dependencies: Dependencies = .live, dispatchQueue: DispatchQueue = DispatchQueue(label: "com.tapp.concurrentDispatchQueue")) {
        self.dependencies = dependencies
        self.dispatchQueue = dispatchQueue
        self.isFirstSession = !dependencies.keychainHelper.hasConfig
        super.init()
    }

    internal let dependencies: Dependencies
    fileprivate var initializationCompletions: [InitializeTappCompletion] = []
    fileprivate var secretsDataTask: URLSessionDataTaskProtocol?
    fileprivate let dispatchQueue: DispatchQueue
    fileprivate var isFirstSession: Bool
    internal weak var delegate: TappDelegate?

    // MARK: - Configuration
    // AppDelegate: Should be called upon didFinishLaunching

    @objc
    public static func start(config: TappConfiguration, delegate: TappDelegate?) {
        single.start(config: config, delegate: delegate)
    }

    func start(config: TappConfiguration, delegate: TappDelegate?) {
        self.delegate = delegate
        self.dependencies.keychainHelper.set(bundleID: config.bundleID)
        self.dependencies.keychainHelper.set(environment: config.env)

        if let storedConfig = self.dependencies.keychainHelper.config {
            if storedConfig.authToken != config.authToken || storedConfig.tappToken != config.tappToken {
                self.dependencies.keychainHelper.save(configuration: config)
            }
        } else {
            self.dependencies.keychainHelper.save(configuration: config)
        }
        self.initializeEngine(completion: nil)
    }

    // MARK: - Generate url
    public static func url(config: AffiliateURLConfiguration,
                    completion: GenerateURLCompletion?) {
        single.url(config: config, completion: completion)
    }

    @objc
    public static func url(config: AffiliateURLConfiguration, completion: ((_ response: GeneratedURLResponse?, _ error: Error?) -> Void)?) {
        url(config: config) { result in
            switch result {
            case .success(let response):
                completion?(response, nil)
            case .failure(let error):
                completion?(nil, error)
            }
        }
    }

    // MARK: - Handle Event
    //For MMP Specific events
    @objc
    public static func handleEvent(config: EventConfig) {
        guard let storedConfig = single.dependencies.keychainHelper.config else { return }
        single.affiliateService?.handleEvent(eventId: config.eventToken,
                                             authToken: storedConfig.authToken)
    }

    //For Tapp Events
    @objc
    public static func handleTappEvent(event: TappEvent) {
        single.handleTappEvent(event: event)
    }

    func handleTappEvent(event: TappEvent) {
        guard event.eventAction.isValid else {
            print("Error: \(TappError.eventActionMissing.localizedDescription)")
            return
        }

        dependencies.services.tappService.sendTappEvent(event: event, completion: nil)
    }


    //MARK: - Deep Links (App Already installed)
    @objc
    public static func shouldProcess(url: URL) -> Bool {
        guard let service = single.affiliateService else { return false }
        return service.shouldProcess(url: url)
    }

    public static func fetchLinkData(for url: URL, completion: LinkDataCompletion?) {
        single.internalFetchLinkData(for: url, completion: completion)
    }

    func internalFetchLinkData(for url: URL, completion: LinkDataCompletion?) {
        guard shouldProcess(url: url) else {
            completion?(Result.failure(TappServiceError.unprocessableEntity))
            return
        }

        initializeEngine { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.dependencies.services.tappService.fetchLinkData(for: url) { result in
                    switch result {
                    case .success(let dto):
                        completion?(Result.success(TappDeferredLinkData(dto: dto, isFirstSession: self.isFirstSession)))
                    case .failure(let error):
                        completion?(Result.failure(error))
                    }
                }
            case .failure(let error):
                completion?(Result.failure(error))
            }
        }
    }

    @objc
    public static func fetchLinkData(for url: URL, completion: ((_ response: TappDeferredLinkData?, _ error: Error?) -> Void)?) {
        fetchLinkData(for: url) { result in
            switch result {
            case .success(let data):
                completion?(data, nil)
            case .failure(let error):
                completion?(nil, error)
            }
        }
    }

    public static func fetchOriginLinkData(completion: LinkDataCompletion?) {
        single.fetchOriginLinkData(completion: completion)
    }

    func fetchOriginLinkData(completion: LinkDataCompletion?) {
        if let dto = dependencies.keychainHelper.config?.linkDataDTO {
            completion?(Result.success(TappDeferredLinkData(dto: dto, isFirstSession: isFirstSession)))
        } else {
            completion?(Result.failure(TappServiceError.notFound))
        }
    }

    @objc
    public static func fetchOriginLinkData(completion: ((_ response: TappDeferredLinkData?, _ error: Error?) -> Void)?) {
        single.fetchOriginLinkData(completion: completion)
    }

    @objc
    func fetchOriginLinkData(completion: ((_ response: TappDeferredLinkData?, _ error: Error?) -> Void)?) {
        fetchOriginLinkData { result in
            switch result {
            case .success(let data):
                completion?(data, nil)
            case .failure(let error):
                completion?(nil, error)
            }
        }
    }

    fileprivate lazy var overridenService: AffiliateServiceProtocol? = {
        if let overrideProtocol = self as? AffiliateServiceOverrideProtocol {
            return overrideProtocol.overrideService
        }
        return nil
    }()
}

internal extension Tapp {
    func url(config: AffiliateURLConfiguration,
                    completion: GenerateURLCompletion?) {
        initializeEngine { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                guard let storedConfig = self.dependencies.keychainHelper.config else {
                    completion?(Result.failure(TappServiceError.invalidData))
                    return
                }
                let request = GenerateURLRequest(influencer: config.influencer,
                                                 adGroup: config.adgroup,
                                                 creative: config.creative,
                                                 mmp: storedConfig.affiliate,
                                                 data: config.data)

                self.dependencies.services.tappService.url(request: request, completion: completion)
            case .failure(let error):
                completion?(Result.failure(error))
            }
        }
    }

    func initializeEngine(completion: VoidCompletion?) {
        dispatchQueue.async {
            guard let config = self.dependencies.keychainHelper.config else {
                completion?(Result.failure(TappError.missingConfiguration))
                return
            }

            if let completion {
                self.initializationCompletions.append(completion)
            }

            if self.secretsDataTask != nil {
                return
            }

            self.secretsDataTask = self.secrets(config: config) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let url):
                    self.initializeAffiliateService(brandedURL: url) { result in
                        switch result {
                        case .success:
                            self.completeInitializationsWithSuccess()
                        case .failure(let error):
                            self.completeInitializations(with: error)
                        }
                    }
                case .failure(let error):
                    let err = TappError.affiliateServiceError(affiliate: config.affiliate, underlyingError: error)
                    print("Error: \(err.localizedDescription)")
                    self.completeInitializations(with: err)
                }
                self.secretsDataTask = nil
            }
        }
    }

    func completeInitializationsWithSuccess() {
        initializationCompletions.forEach({ $0(.success(()))})
        initializationCompletions.removeAll()
    }

    func completeInitializations(with error: Error) {
        initializationCompletions.forEach({ $0(.failure(error)) })
        initializationCompletions.removeAll()
    }

    func secrets(config: TappConfiguration, completion: ResolvedOptionalURLCompletion?) -> URLSessionDataTaskProtocol? {
        guard let storedConfig = dependencies.keychainHelper.config else {
            completion?(Result.failure(TappError.missingConfiguration))
            return nil
        }

        return dependencies.services.tappService.secrets(affiliate: config.affiliate) { [unowned config, weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                storedConfig.set(appToken: response.secret)
                self.dependencies.keychainHelper.save(configuration: storedConfig)
                completion?(.success(response.brandedURL)) //Fingerprint URL
            case .failure(let error):
                let err = TappError.affiliateServiceError(affiliate: config.affiliate, underlyingError: error)
                print("Error: \(err.localizedDescription)")
                completion?(Result.failure(err))
            }
        }
    }

    func initializeAffiliateService(brandedURL: URL?, completion: VoidCompletion?) {
        guard let service = affiliateService else {
            let error = TappError.missingParameters(details: "Affiliate service not configured")
            print("Error: \(error.localizedDescription)")
            completion?(Result.failure(error))
            return
        }

        if service.isInitialized {
            completion?(Result.success(()))
            return
        }

        guard let storedConfig = dependencies.keychainHelper.config else {
            let error = TappError.missingParameters(details:
                                                        "Missing required credentials or bundle identifier")
            print("Error: \(error.localizedDescription)")
            completion?(Result.failure(error))
            return
        }

        service.initialize(environment: storedConfig.env, brandedURL: brandedURL) { [weak self] result in
            switch result {
            case .success:
                self?.setProcessedReferralEngine()
            case .failure:
                break
            }
            completion?(result)
        }
    }

    // MARK: - Referral Engine State Management
    func setProcessedReferralEngine() {
        guard let storedConfig = dependencies.keychainHelper.config else { return }
        storedConfig.set(hasProcessedReferralEngine: true)
        dependencies.keychainHelper.save(configuration: storedConfig)
    }

    func hasProcessedReferralEngine() -> Bool {
        return dependencies.keychainHelper.config?.hasProcessedReferralEngine ?? false
    }

    //MARK: - Deep Links (App Already installed)
    func shouldProcess(url: URL) -> Bool {
        return dependencies.services.tappService.shouldProcess(url: url)
    }
}

extension Tapp {
    var affiliateService: AffiliateServiceProtocol? {
        guard let config = dependencies.keychainHelper.config else {
            return nil
        }

        var service: AffiliateServiceProtocol?
        switch config.affiliate {
        case .tapp:
            service = dependencies.services.tappService
        case .adjust, .appsflyer:
            service = overridenService
        }
        service?.delegate = self
        return service
    }
}

extension Tapp: DeferredLinkDelegate {
    public func didReceiveDeferredLink(_ url: URL) {
        initializeEngine { [weak self] result in
            switch result {
            case .success:
                self?.dependencies.services.tappService.handleImpression(url: url, completion: nil)

                guard self?.delegate != nil else { return }

                self?.dependencies.services.tappService.fetchLinkData(for: url) { [weak self] result in
                    guard let self else { return }

                    switch result {
                    case .success(let dto):
                        if let storedConfig = self.dependencies.keychainHelper.config {
                            storedConfig.set(originURL: dto.tappURL)
                            storedConfig.set(originAttributedTappURL: dto.attributedTappURL)
                            storedConfig.set(originInfluencer: dto.influencer)
                            storedConfig.set(originData: dto.data)
                            self.dependencies.keychainHelper.save(configuration: storedConfig)
                        }

                        self.delegate?.didOpenApplication?(with: TappDeferredLinkData(dto: dto,
                                                                               isFirstSession: self.isFirstSession))
                    case .failure(let error):
                        self.delegate?.didFailResolvingURL?(url: url, error: error)
                    }
                    self.isFirstSession = false
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

extension Tapp: AffiliateServiceDelegate {
    func didReceive(fingerprintResponse: FingerprintResponse) {
        guard let tappURL = fingerprintResponse.tappURL else { return }
        guard let deeplink = fingerprintResponse.deeplink else { return }
        guard let attributedTappURL = fingerprintResponse.attributedTappURL else { return }
        guard let influencer = fingerprintResponse.influencer else { return }

        self.dependencies.services.tappService.handleImpression(url: deeplink, completion: nil)


        let linkData = TappDeferredLinkData(tappURL: tappURL,
                                            attributedTappURL: attributedTappURL,
                                            influencer: influencer,
                                            data: fingerprintResponse.validData,
                                            isFirstSession: self.isFirstSession)
        delegate?.didOpenApplication?(with: linkData)
    }
}
