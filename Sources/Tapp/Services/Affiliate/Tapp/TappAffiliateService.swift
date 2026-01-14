import Foundation
import TappNetworking
import WebKit

public enum ResolvedURLError: Error {
    case cannotResolveURL
    case cannotResolveDeepLink
}

enum TappAffiliateServiceError: Error {
    case undefined
    case decodingError
}

typealias FingerprintCompletion = (_ result: Result<FingerprintResponse, Error>) -> Void

protocol TappAffiliateServiceProtocol: AffiliateServiceProtocol, TappServiceProtocol {}

final class TappAffiliateService: TappAffiliateServiceProtocol {

    var isInitialized: Bool = false
    var delegate: AnyObject?

    private let keychainHelper: KeychainHelperProtocol
    private let networkClient: NetworkClientProtocol
    private let webLoaderProvider: WebLoaderProviderProtocol
    private(set) var webLoader: WebLoaderProtocol?

    private var affiliateServiceDelegate: AffiliateServiceDelegate? {
        return delegate as? AffiliateServiceDelegate
    }

    init(keychainHelper: KeychainHelperProtocol, networkClient: NetworkClientProtocol, webLoaderProvider: WebLoaderProviderProtocol) {
        self.keychainHelper = keychainHelper
        self.networkClient = networkClient
        self.webLoaderProvider = webLoaderProvider
    }

    func initialize(environment: Environment, brandedURL: URL?, completion: VoidCompletion?) {
        guard keychainHelper.config != nil else {
            completion?(.failure(TappServiceError.invalidData))
            return
        }

        fetchDevice { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let device):
                guard let config = self.keychainHelper.config else {
                    completion?(.failure(TappServiceError.invalidData))
                    return
                }
                config.set(deviceID: device.id)
                self.keychainHelper.save(configuration: config)

                if config.isAlreadyVerified == false {
                    self.beginWebFlow(config: config, brandedURL: brandedURL, completion: completion)
                }

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    private func beginWebFlow(config: TappConfiguration, brandedURL: URL?, completion: VoidCompletion?) {
        let hasOriginURL = keychainHelper.config?.originURL != nil

        if let brandedURL, !hasOriginURL {
            let loader = webLoaderProvider.make(brandedURL: brandedURL)
            loader.delegate = self

            self.webLoader = loader

            loader.load()
        }

        completion?(Result.success(()))
    }

    func handleCallback(with url: String, completion: ResolvedURLCompletion?) {
        guard let actualURL = URL(string: url) else {
            completion?(Result.failure(ResolvedURLError.cannotResolveURL))
            return
        }
        completion?(Result.success(actualURL))
    }

    func url(request: GenerateURLRequest, completion: GenerateURLCompletion?) {
        url(uniqueID: request.influencer,
            adGroup: request.adGroup,
            creative: request.creative,
            data: request.data,
            completion: completion)
    }

    private func url(uniqueID: String,
                     adGroup: String?,
                     creative: String?,
                     data: [String: String]?,
                     completion: GenerateURLCompletion?) {
        guard let config = keychainHelper.config, let bundleID = config.bundleID else {
            completion?(.failure(TappServiceError.invalidData))
            return
        }
        let createRequest = CreateAffiliateURLRequest(tappToken: config.tappToken,
                                                      bundleID: bundleID,
                                                      mmp: config.affiliate.rawValue,
                                                      influencer: uniqueID,
                                                      adGroup: adGroup,
                                                      creative: creative,
                                                      data: data)
        let endpoint = TappEndpoint.generateURL(createRequest)
        guard let request = endpoint.request else {
            completion?(Result.failure(TappServiceError.invalidRequest))
            return
        }

        networkClient.executeAuthenticated(request: request) { result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(GeneratedURLResponse.self, from: data)
                    completion?(Result.success(response))
                } catch {
                    completion?(Result.failure(TappAffiliateServiceError.decodingError))
                }
            case .failure(let error):
                completion?(Result.failure(error))
            }
        }
    }

    func handleImpression(url: URL, completion: VoidCompletion?) {
        guard let config = keychainHelper.config, let bundleID = config.bundleID else {
            completion?(.failure(TappServiceError.invalidData))
            return
        }
        let impressionRequest = ImpressionRequest(tappToken: config.tappToken, bundleID: bundleID, deepLink: url)
        commonVoid(with: TappEndpoint.deeplink(impressionRequest), completion: completion)
    }

    func fetchDevice(completion: DeviceCompletion?) {
        guard let config = keychainHelper.config, let bundleID = config.bundleID else {
            completion?(Result.failure(TappServiceError.invalidData))
            return
        }

        let deviceRequest = DeviceRequest(tappToken: config.tappToken,
                                          bundleID: bundleID,
                                          mmp: config.affiliate.rawValue,
                                          deviceID: config.deviceID)

        switch config.env {
        case .sandbox:
            internalFetchDevice(request: deviceRequest) { [weak self, config] result in
                guard let self else { return }
                switch result {
                case .success(let device):
                    if device.active == false {
                        config.set(isAlreadyVerified: false)
                        self.keychainHelper.save(configuration: config)
                    }
                case .failure:
                    break
                }
                completion?(result)
            }
        case .production:
            if let deviceID = config.deviceID {
                completion?(.success(Device(id: deviceID, active: true)))
                return
            }
            internalFetchDevice(request: deviceRequest, completion: completion)
        }
    }

    func internalFetchDevice(request: DeviceRequest, completion: DeviceCompletion?) {
        let endpoint = TappEndpoint.device(request)

        guard let request = endpoint.request else {
            completion?(Result.failure(TappServiceError.invalidRequest))
            return
        }

        networkClient.executeAuthenticated(request: request) { result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(DeviceResponse.self, from: data)
                    completion?(Result.success(response.device))
                } catch {
                    completion?(Result.failure(error))
                }
            case .failure(let error):
                completion?(Result.failure(error))
            }
        }
    }

    func secrets(affiliate: Affiliate, completion: SecretsCompletion?) -> URLSessionDataTaskProtocol? {
        guard let config = keychainHelper.config, let bundleID = config.bundleID else {
            completion?(Result.failure(TappServiceError.invalidData))
            return nil
        }

        let secretsRequest = SecretsRequest(tappToken: config.tappToken, bundleID: bundleID, mmp: affiliate.rawValue)
        
        let endpoint = TappEndpoint.secrets(secretsRequest)

        guard let request = endpoint.request else {
            completion?(Result.failure(TappServiceError.invalidRequest))
            return nil
        }

        return networkClient.executeAuthenticated(request: request) { result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(SecretsResponse.self, from: data)
                    completion?(Result.success(response))
                } catch {
                    completion?(Result.failure(TappAffiliateServiceError.decodingError))
                }
            case .failure(let error):
                completion?(Result.failure(error))
            }
        }
    }

    func sendTappEvent(event: TappEvent, completion: VoidCompletion?) {
        guard let config = keychainHelper.config, let bundleID = config.bundleID else {
            completion?(Result.failure(TappServiceError.invalidData))
            return
        }
        let eventRequest = TappEventRequest(tappToken: config.tappToken,
                                            bundleID: bundleID,
                                            eventName: event.eventAction.name,
                                            url: config.originURL?.absoluteString)
        let endpoint = TappEndpoint.tappEvent(eventRequest)
        commonVoid(with: endpoint, completion: completion)
    }

    func handleEvent(eventId: String, authToken: String?) {
        print("Use the handleTappEvent method to handle Tapp events")

    }

    func shouldProcess(url: URL) -> Bool {
        return url.isTappURL
    }

    func fetchLinkData(for url: URL, completion: LinkDataDTOCompletion?) {
        if let dto = keychainHelper.config?.linkDataDTO {
            completion?(Result.success(dto))
            return
        }
        
        guard let linkToken = url.param(for: AdjustURLParamKey.token.rawValue) else {
            completion?(.failure(TappServiceError.invalidURL))
            return
        }

        fetchLinkData(linkToken: linkToken, completion: completion)
    }
}

private extension TappAffiliateService {
    func commonVoid(with endpoint: TappEndpoint, completion: VoidCompletion?) {
        guard let request = endpoint.request else {
            completion?(Result.failure(TappServiceError.invalidRequest))
            return
        }

        networkClient.executeAuthenticated(request: request) { result in
            switch result {
            case .success:
                completion?(Result.success(()))
            case .failure(let error):
                completion?(Result.failure(error))
            }
        }
    }

    func fetchLinkData(linkToken: String, completion: LinkDataDTOCompletion?) {
        guard let config = keychainHelper.config, let bundleID = config.bundleID else {
            completion?(Result.failure(TappServiceError.invalidData))
            return
        }

        let linkRequest = TappLinkDataRequest(tappToken: config.tappToken,
                                              bundleID: bundleID,
                                              linkToken: linkToken)
        let endpoint = TappEndpoint.linkData(linkRequest)

        guard let request = endpoint.request else {
            completion?(Result.failure(TappServiceError.invalidRequest))
            return
        }

        networkClient.executeAuthenticated(request: request) { result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(TappDeferredLinkDataDTO.self, from: data)
                    completion?(Result.success(response))
                } catch {
                    completion?(Result.failure(error))
                }
            case .failure(let error):
                completion?(Result.failure(error))
            }
        }
    }

    func sendFingerprint(message: WKScriptMessage, completion: FingerprintCompletion?) {
        guard let config = keychainHelper.config else {
            completion?(Result.failure(TappServiceError.invalidData))
            return
        }

        let fingerprint = Fingerprint.generate(tappToken: config.tappToken,
                                               webBody: message.body as? String,
                                               deviceID: deviceID)
        let endpoint = TappEndpoint.fingerpint(fingerprint)
        guard let request = endpoint.request else {
            completion?(Result.failure(TappServiceError.invalidRequest))
            return
        }

        networkClient.executeAuthenticated(request: request) { result in
            switch result {
                case .success(let data):
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(FingerprintResponse.self, from: data)
                    completion?(Result.success(response))
                } catch {
                    completion?(Result.failure(error))
                }
            case .failure:
                completion?(.failure(TappServiceError.invalidRequest))
            }
        }
    }
}

//MARK: - WebLoaderDelegate -

extension TappAffiliateService: WebLoaderDelegate {
    func didReceive(message: WKScriptMessage) {
        sendFingerprint(message: message) { [weak self] result in
            switch result {
            case .success(let response):
                self?.updateConfiguration(response: response)
                self?.affiliateServiceDelegate?.didReceive(fingerprintResponse: response)
            case .failure:
                break
            }
        }
    }
}

private enum AdjustURLParamKey: String {
    case token = "adj_t"
}

extension URL {
    var host: String? {
        let components = URLComponents(string: absoluteString)
        if let host = components?.host {
            let paths = host.split(separator: ".")
            let lastTwoItems = paths.suffix(2)
            return lastTwoItems.joined(separator: ".")
        }
        return nil
    }

    var isTappURL: Bool {
        guard let host else {
            return false
        }
        return host == "tapp.so"
    }
}

private extension TappAffiliateService {
    func updateConfiguration(response: FingerprintResponse) {
        guard let config = keychainHelper.config else { return }
        guard let deviceID = response.deviceID?.id else { return }

        if let url = response.tappURL {
            config.set(originURL: url)
        }
        if let attributedTappURL = response.attributedTappURL {
            config.set(originAttributedTappURL: attributedTappURL)
        }
        if let influencer = response.influencer {
            config.set(originInfluencer: influencer)
        }
        if let data = response.data {
            config.set(originData: data)
        }

        config.set(deviceID: deviceID)
        config.set(isAlreadyVerified: response.isAlreadyVerified)

        keychainHelper.save(configuration: config)
    }

    var deviceID: String? {
        return keychainHelper.config?.deviceID
    }
}

private extension TappConfiguration {
    var linkDataDTO: TappDeferredLinkDataDTO? {
        guard let originURL, let originAttributedTappURL, let originInfluencer else { return nil }
        return TappDeferredLinkDataDTO(tappURL: originURL,
                                       attributedTappURL: originAttributedTappURL,
                                       influencer: originInfluencer,
                                       data: validData)
    }

    var validData: [String: String]? {
        guard let originData else { return nil }
        var dict: [String: String] = [:]
        for key in originData.keys {
            if let value = originData[key] {
                dict[key] = value
            }
        }
        return dict
    }
}
