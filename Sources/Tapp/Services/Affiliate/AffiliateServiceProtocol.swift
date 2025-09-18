import Foundation
import TappNetworking

public enum AffiliateServiceError: Error {
    case missingToken
}

public protocol AffiliateServiceProtocol {
    var isInitialized: Bool { get }
    func initialize(environment: Environment,
                    completion: VoidCompletion?)

    func handleCallback(with url: String, completion: ResolvedURLCompletion?)
    func handleEvent(eventId: String, authToken: String?)
}
