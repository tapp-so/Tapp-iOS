import Foundation
import TappNetworking

enum ResolvedURLError: Error {
    case cannotResolveURL
    case cannotResolveDeepLink
}

protocol TappAffiliateServiceProtocol: AffiliateServiceProtocol, TappServiceProtocol {}

final class TappAffiliateService: TappAffiliateServiceProtocol {

    let isInitialized: Bool = true
    private let keychainHelper: KeychainHelperProtocol
    private let networkClient: NetworkClientProtocol

    init(keychainHelper: KeychainHelperProtocol, networkClient: NetworkClientProtocol) {
        self.keychainHelper = keychainHelper
        self.networkClient = networkClient
    }

    func initialize(environment: Environment, completion: VoidCompletion?) {
        Logger.logInfo("Initializing Tapp... Not implemented")
        completion?(.success(()))
    }

    func handleCallback(with url: String, completion: ResolvedURLCompletion?) {
        Logger.logInfo("Handling Tapp callback with URL: \(url)")
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
        guard let config = keychainHelper.config, let bundleID = config.bundleID else { return }
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
                    completion?(Result.failure(error))
                }
            case .failure(let error):
                completion?(Result.failure(error))
            }
        }
    }

    func handleImpression(url: URL, completion: VoidCompletion?) {
        guard let config = keychainHelper.config, let bundleID = config.bundleID else { return }
        let impressionRequest = ImpressionRequest(tappToken: config.tappToken, bundleID: bundleID, deepLink: url)
        commonVoid(with: TappEndpoint.deeplink(impressionRequest), completion: completion)
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
                    completion?(Result.failure(error))
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
        Logger.logInfo("Use the handleTappEvent method to handle Tapp events")
    }

    func shouldProcess(url: URL) -> Bool {
        return url.param(for: AdjustURLParamKey.token.rawValue) != nil
    }

    func fetchLinkData(for url: URL, completion: LinkDataDTOCompletion?) {
        guard let linkToken = url.param(for: AdjustURLParamKey.token.rawValue) else { return }

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
}

private enum AdjustURLParamKey: String {
    case token = "adj_t"
}
