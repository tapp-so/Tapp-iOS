import Foundation
@testable import Tapp

final class AffiliateServiceDelegateMock: AffiliateServiceDelegate {
    var didReceiveCalled: Bool = false
    var tc: TCResponse?
    func didReceive(tc: TCResponse) {
        self.didReceiveCalled = true
        self.tc = tc
    }
}
