import Foundation
import TappNetworking
@testable import Tapp

final class TappAffiliateServiceMock: TappAffiliateServiceProtocol {
    let id: UUID = UUID()

    var isInitialized: Bool = false

    var delegate: AnyObject?

    var initializeCalled: Bool = false
    var initializeEnvironment: Environment?
    var initializeBrandedURL: URL?
    var initializeError: Error?
    func initialize(environment: Environment, brandedURL: URL?, completion: VoidCompletion?) {
        initializeCalled = true
        initializeEnvironment = environment
        initializeBrandedURL = brandedURL

        if let initializeError {
            completion?(.failure(initializeError))
        } else {
            completion?(.success(()))
        }
    }

    var handleCallbackCalled: Bool = true
    var handleCallbackURLString: String?
    var handleCallbackURL: URL?
    var handleCallbackError: Error?
    func handleCallback(with url: String, completion: ResolvedURLCompletion?) {
        handleCallbackCalled = true
        handleCallbackURLString = url

        if let handleCallbackError {
            completion?(.failure(handleCallbackError))
            return
        }

        if let handleCallbackURL {
            completion?(.success(handleCallbackURL))
            return
        }
    }

    var handleEventCalled: Bool = false
    var handleEventEventId: String?
    var handleEventAuthToken: String?
    func handleEvent(eventId: String, authToken: String?) {
        handleEventCalled = true
        handleEventEventId = eventId
        handleEventAuthToken = authToken
    }

    var shouldProcessCalled: Bool = false
    var shouldProcessURL: Bool = true
    var shouldProcessURLValue: URL?
    func shouldProcess(url: URL) -> Bool {
        shouldProcessCalled = true
        shouldProcessURLValue = url
        return shouldProcessURL
    }

    var urlCalled: Bool = false
    var urlRequest: GenerateURLRequest?
    var urlResponse: GeneratedURLResponse?
    var urlError: Error?
    func url(request: GenerateURLRequest, completion: GenerateURLCompletion?) {
        urlCalled = true
        urlRequest = request
        if let urlError {
            completion?(.failure(urlError))
            return
        }

        if let urlResponse {
            completion?(.success(urlResponse))
            return
        }
    }

    var handleImpressionCalled: Bool = false
    var handleImpressionURL: URL?
    var handleImpressionError: Error?
    func handleImpression(url: URL, completion: VoidCompletion?) {
        handleImpressionCalled = true
        handleImpressionURL = url
        if let handleImpressionError {
            completion?(.failure(handleImpressionError))
            return
        } else {
            completion?(.success(()))
        }
    }

    var sendTappEventCalled: Bool = false
    var sendTappEventValue: TappEvent?
    var sendTappEventError: Error?
    var sendTappEventCount: Int = 0
    func sendTappEvent(event: TappEvent, completion: VoidCompletion?) {
        sendTappEventCalled = true
        sendTappEventValue = event
        sendTappEventCount += 1
        if let sendTappEventError {
            completion?(.failure(sendTappEventError))
            return
        } else {
            completion?(.success(()))
        }
    }

    var secretsCalled: Bool = false
    var secretsCalledCount: Int = 0
    var secretsAffiliate: Affiliate?
    var secretsResponse: SecretsResponse?
    var secretsError: Error?
    var secretsDataTask: URLSessionDataTaskMock = URLSessionDataTaskMock()
    func secrets(affiliate: Affiliate, completion: SecretsCompletion?) -> URLSessionDataTaskProtocol? {
        secretsCalled = true
        secretsCalledCount += 1
        secretsAffiliate = affiliate
        if let secretsError {
            completion?(.failure(secretsError))
            return secretsDataTask
        }
        
        if let secretsResponse {
            completion?(.success(secretsResponse))
        }

        return secretsDataTask
    }

    var fetchLinkDataCalled: Bool = false
    var fetchLinkDataURL: URL?
    var fetchLinkDataDTO: TappDeferredLinkDataDTO?
    var fetchLinkDataError: Error?
    func fetchLinkData(for url: URL, completion: LinkDataDTOCompletion?) {
        fetchLinkDataCalled = true
        fetchLinkDataURL = url

        if let fetchLinkDataError {
            completion?(.failure(fetchLinkDataError))
        } else if let fetchLinkDataDTO {
            completion?(.success(fetchLinkDataDTO))
        }
    }
}
