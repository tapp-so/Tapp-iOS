import Foundation
@testable import Tapp

final class TappDelegateMock: TappDelegate {
    var didOpenApplicationCalled: Bool = false
    var didOpenApplicationData: TappDeferredLinkData?
    func didOpenApplication(with data: TappDeferredLinkData) {
        didOpenApplicationCalled = true
        didOpenApplicationData = data
    }

    var didFailResolvingURLCalled: Bool = false
    var didFailResolvingURLError: Error?
    func didFailResolvingURL(url: URL, error: Error) {
        didFailResolvingURLCalled = true
        didFailResolvingURLError = error
    }
}
