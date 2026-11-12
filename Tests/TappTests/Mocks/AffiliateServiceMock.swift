import Foundation
import TappNetworking
@testable import Tapp

/// Minimal `AffiliateServiceProtocol` stand-in for an MMP service (e.g. Adjust).
final class AffiliateServiceMock: AffiliateServiceProtocol {
    var isInitialized: Bool = false
    var delegate: AnyObject?

    var initializeCalled: Bool = false
    var initializeEnvironment: Environment?
    func initialize(environment: Environment, brandedURL: URL?, completion: VoidCompletion?) {
        initializeCalled = true
        initializeEnvironment = environment
        isInitialized = true
        completion?(.success(()))
    }

    func handleCallback(with url: String, completion: ResolvedURLCompletion?) {
        guard let actualURL = URL(string: url) else {
            completion?(.failure(ResolvedURLError.cannotResolveURL))
            return
        }
        completion?(.success(actualURL))
    }

    func handleEvent(eventId: String, authToken: String?) {}

    func shouldProcess(url: URL) -> Bool {
        return false
    }
}

/// Mirrors how Tapp-Adjust plugs in: `Tapp` conforming to `AffiliateServiceOverrideProtocol`.
final class TappWithOverrideServiceMock: Tapp, AffiliateServiceOverrideProtocol {
    let overrideServiceMock: AffiliateServiceMock = .init()

    var overrideService: AffiliateServiceProtocol {
        return overrideServiceMock
    }
}
