import Foundation
import TappNetworking

public enum AffiliateServiceError: Error {
    case missingToken
}

protocol AffiliateServiceDelegate: AnyObject {
    func didReceive(fingerprintResponse: FingerprintResponse)
}

public protocol AffiliateServiceProtocol: AnyObject {
    var isInitialized: Bool { get }
    var delegate: AnyObject? { get set }
    func initialize(environment: Environment,
                    brandedURL: URL?,
                    completion: VoidCompletion?)

    func handleCallback(with url: String, completion: ResolvedURLCompletion?)
    func handleEvent(eventId: String, authToken: String?)
    func shouldProcess(url: URL) -> Bool
}

public protocol AffiliateServiceOverrideProtocol {
    var overrideService: AffiliateServiceProtocol { get }
}
