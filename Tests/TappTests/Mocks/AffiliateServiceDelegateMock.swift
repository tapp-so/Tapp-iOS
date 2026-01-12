import Foundation
@testable import Tapp

final class AffiliateServiceDelegateMock: AffiliateServiceDelegate {
    var didReceiveCalled: Bool = false
    var receivedResponse: FingerprintResponse?
    func didReceive(fingerprintResponse: FingerprintResponse) {
        didReceiveCalled = true
        receivedResponse = fingerprintResponse
    }
}
