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
        super.init()
    }

    internal let dependencies: Dependencies
    fileprivate var initializationCompletions: [InitializeTappCompletion] = []
    fileprivate var secretsDataTask: URLSessionDataTaskProtocol?
    fileprivate let dispatchQueue: DispatchQueue
    fileprivate var isFirstSession: Bool = false
    internal weak var delegate: TappDelegate?

    // MARK: - Configuration
    // AppDelegate: Should be called upon didFinishLaunching

    @objc
    public static func start(config: TappConfiguration, delegate: TappDelegate?) {
        single.start(config: config, delegate: delegate)
    }

    func start(config: TappConfiguration, delegate: TappDelegate?) {
        TappLog.logInfo(message: "Will start Tapp SDK", environment: config.env, context: "Initialization")
        self.delegate = delegate
        self.dependencies.keychainHelper.set(bundleID: config.bundleID)
        self.dependencies.keychainHelper.set(environment: config.env)
        self.isFirstSession = !dependencies.keychainHelper.hasConfig

        let environment = config.env
        let context = "Initialization"

        if let storedConfig = self.dependencies.keychainHelper.config {
            if storedConfig.authToken != config.authToken || storedConfig.tappToken != config.tappToken {
                self.dependencies.keychainHelper.save(configuration: config)
                TappLog.logInfo(message: "Did update config with new tokens",
                                environment: environment,
                                context: context)
            }
        } else {
            self.dependencies.keychainHelper.save(configuration: config)
            TappLog.logInfo(message: "Did set config",
                            environment: environment,
                            context: context)
        }
        self.initializeEngine { result in
            switch result {
            case .success:
                TappLog.logInfo(message: "Tapp initialization completed",
                                environment: environment,
                                context: context)
            case .failure(let error):
                TappLog.logError(error,
                                 environment: environment,
                                 context: context)
            }
        }
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
        fetchOriginLinkData { [weak self] result in
            guard let self else { return }
            let environment = self.dependencies.keychainHelper.currentEnvironment
            let context = "Fetch origin link data"
            switch result {
            case .success(let data):
                TappLog.logInfo(message: "Did receive link data \(data)",
                                environment: environment,
                                context: context)
                completion?(data, nil)
            case .failure(let error):
                TappLog.logError(error, environment: environment, context: context)
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
            let environment = self.dependencies.keychainHelper.currentEnvironment
            let context = "Generate Tapp URL"
            switch result {
            case .success:
                TappLog.logInfo(message: "Will attempt to generate url",
                                environment: environment,
                                context: context)
                guard let storedConfig = self.dependencies.keychainHelper.config else {
                    let error = TappServiceError.invalidData
                    completion?(Result.failure(error))
                    TappLog.logError(error, environment: environment, context: context)
                    return
                }
                let request = GenerateURLRequest(influencer: config.influencer,
                                                 adGroup: config.adgroup,
                                                 creative: config.creative,
                                                 mmp: storedConfig.affiliate,
                                                 data: config.data)

                self.dependencies.services.tappService.url(request: request) { result in
                    switch result {
                    case .success(let response):
                        TappLog.logInfo(message: "Did generate url: \(response)",
                                        environment: environment,
                                        context: context)
                    case .failure(let error):
                        TappLog.logError(error, environment: environment, context: context)
                        break
                    }
                    completion?(result)
                }
            case .failure(let error):
                TappLog.logError(error, environment: environment, context: context)
                completion?(Result.failure(error))
            }
        }
    }

    func initializeEngine(completion: VoidCompletion?) {
        dispatchQueue.async {
            let environment = self.dependencies.keychainHelper.currentEnvironment
            let context = "Initialization"
            TappLog.logInfo(message: "Will initialize Tapp engine",
                            environment: environment,
                            context: context)
            
            guard let config = self.dependencies.keychainHelper.config else {
                let error = TappError.missingConfiguration
                completion?(Result.failure(error))
                TappLog.logError(error,
                                 environment: environment,
                                 context: context)
                return
            }

            if let completion {
                self.initializationCompletions.append(completion)
            }

            if self.secretsDataTask != nil {
                TappLog.logInfo(message: "Existing initialization in progress, will return.",
                                environment: environment,
                                context: context)
                return
            }

            self.secretsDataTask = self.secrets(config: config) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let url):
                    TappLog.logInfo(message: "Did receive branded URL: \(url?.absoluteString ?? "no URL")",
                                    environment: environment,
                                    context: "\(context) (keys)")
                    self.initializeAffiliateService(brandedURL: url) { result in
                        switch result {
                        case .success:
                            TappLog.logInfo(message: "Did initialize affiliate service keys",
                                            environment: environment,
                                            context: "\(context) (keys)")
                            self.completeInitializationsWithSuccess()
                        case .failure(let error):
                            TappLog.logError(error, environment: environment, context: "\(context) (keys")
                            self.completeInitializations(with: error)
                        }
                    }
                case .failure(let error):
                    let err = TappError.affiliateServiceError(affiliate: config.affiliate, underlyingError: error)
                    TappLog.logError(error, environment: environment, context: "\(context) (keys)")
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
        let environment = dependencies.keychainHelper.currentEnvironment
        let context = "Tapp keys"
        guard let storedConfig = dependencies.keychainHelper.config else {
            let error = TappError.missingConfiguration
            completion?(Result.failure(error))
            TappLog.logError(error, environment: environment, context: context)
            return nil
        }

        TappLog.logInfo(message: "Will attempt to fetch keys",
                        environment: environment,
                        context: context)
        return dependencies.services.tappService.secrets(affiliate: config.affiliate) { [unowned config, weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                storedConfig.set(appToken: response.secret)
                self.dependencies.keychainHelper.save(configuration: storedConfig)
                completion?(.success(response.brandedURL)) //Fingerprint URL
                TappLog.logInfo(message: "Did fetch keys",
                                environment: environment,
                                context: context)
            case .failure(let error):
                let err = TappError.affiliateServiceError(affiliate: config.affiliate, underlyingError: error)
                TappLog.logError(err, environment: environment, context: context)
                completion?(Result.failure(err))
            }
        }
    }

    func initializeAffiliateService(brandedURL: URL?, completion: VoidCompletion?) {
        let environment = dependencies.keychainHelper.currentEnvironment
        guard let service = affiliateService else {
            let error = TappError.missingParameters(details: "Affiliate service not configured")
            TappLog.logError(error, environment: environment, context: "Initialization (Affiliate Service)")
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
            TappLog.logError(error, environment: environment, context: "Initialization (Affiliate Service)")
            completion?(Result.failure(error))
            return
        }

        service.initialize(environment: storedConfig.env, brandedURL: brandedURL) { [weak self] result in
            switch result {
            case .success:
                self?.setProcessedReferralEngine()
                TappLog.logInfo(message: "Did initialize affiliate service", environment: environment, context: "Initialization (Affiliate Service)")
            case .failure(let error):
                TappLog.logError(error, environment: environment, context: "Initialization (Affiliate Service)")
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
        let value = dependencies.services.tappService.shouldProcess(url: url)

        let environment = dependencies.keychainHelper.currentEnvironment
        let context = "Should process url"
        if value == true {
            TappLog.logInfo(message: "Tapp url found", environment: environment, context: context)
        } else {
            TappLog.logInfo(message: "URL is not a Tapp url", environment: environment, context: context)
        }

        return value
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
            guard let self else { return }

            let environment = self.dependencies.keychainHelper.currentEnvironment
            let context = "Did receive deferred link"
            switch result {
            case .success:
                self.dependencies.services.tappService.handleImpression(url: url) { result in
                    switch result {
                    case .success:
                        TappLog.logInfo(message: "Did track impression",
                                        environment: environment,
                                        context: context)
                    case .failure(let error):
                        TappLog.logError(error,
                                         environment: environment,
                                         context: context)
                    }
                }

                guard self.delegate != nil else { return }

                self.dependencies.services.tappService.fetchLinkData(for: url) { [weak self] result in
                    guard let self else { return }

                    switch result {
                    case .success(let dto):
                        if let storedConfig = self.dependencies.keychainHelper.config {
                            TappLog.logInfo(message: "Will update config with Tapp url: \(dto.tappURL)",
                                            environment: environment,
                                            context: context)
                            storedConfig.set(originURL: dto.tappURL)

                            TappLog.logInfo(message: "Will update config with attributed Tapp url: \(dto.attributedTappURL)",
                                            environment: environment,
                                            context: context)
                            storedConfig.set(originAttributedTappURL: dto.attributedTappURL)

                            TappLog.logInfo(message: "Will update config with influencer: \(dto.influencer)",
                                            environment: environment,
                                            context: context)
                            storedConfig.set(originInfluencer: dto.influencer)

                            storedConfig.set(originData: dto.data)
                            self.dependencies.keychainHelper.save(configuration: storedConfig)
                        }

                        if let delegate = self.delegate {
                            TappLog.logInfo(message: "Will inform delegate \(String(describing: delegate)) with link data \(dto)",
                                            environment: environment,
                                            context: context)

                            delegate.didOpenApplication?(with: TappDeferredLinkData(dto: dto,
                                                                                   isFirstSession: self.isFirstSession))
                        } else {
                            TappLog.logInfo(message: "No delegate set",
                                            environment: environment,
                                            context: context)
                        }

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
        let environment = dependencies.keychainHelper.currentEnvironment
        let context = "Did receive device match response"
        guard let tappURL = fingerprintResponse.tappURL else {
            TappLog.logInfo(message: "Missing Tapp URL", environment: environment, context: context)
            return
        }
        guard let deeplink = fingerprintResponse.deeplink else {
            TappLog.logInfo(message: "Missing Tapp deeplink", environment: environment, context: context)
            return
        }
        guard let attributedTappURL = fingerprintResponse.attributedTappURL else {
            TappLog.logInfo(message: "Missing attributed Tapp URL", environment: environment, context: context)
            return
        }
        guard let influencer = fingerprintResponse.influencer else {
            TappLog.logInfo(message: "Missing Influencer", environment: environment, context: context)
            return
        }

        TappLog.logInfo(message: "Will attempt to track impression",
                        environment: environment,
                        context: context)
        dependencies.services.tappService.handleImpression(url: deeplink) { result in
            switch result {
            case .success:
                TappLog.logInfo(message: "Did track impression",
                                environment: environment,
                                context: context)
            case .failure(let error):
                TappLog.logError(error,
                                 environment: environment,
                                 context: context)
            }
        }

        let linkData = TappDeferredLinkData(tappURL: tappURL,
                                            attributedTappURL: attributedTappURL,
                                            influencer: influencer,
                                            data: fingerprintResponse.validData,
                                            isFirstSession: self.isFirstSession)
        TappLog.logInfo(message: "Will inform delegate with link data \(linkData)",
                        environment: environment,
                        context: context)
        delegate?.didOpenApplication?(with: linkData)
    }
}

public extension Tapp {
    static func clearTappKeychainData() {
        single.clearTappKeychainData()
    }

    func clearTappKeychainData() {
        guard dependencies.keychainHelper.currentEnvironment == .sandbox else { return }
        if let bundleID = dependencies.keychainHelper.config?.bundleID {
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: "tapp_c_\(bundleID)_s"]
            SecItemDelete(query as CFDictionary)
        }
    }
}
