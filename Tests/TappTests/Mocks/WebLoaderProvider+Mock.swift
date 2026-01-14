import Foundation
import WebKit
@testable import Tapp

final class WebLoaderProviderMock: WebLoaderProviderProtocol {
    func make(brandedURL: URL) -> WebLoaderProtocol {
        return WebLoaderMock(brandedURL: brandedURL)
    }
}

final class WebLoaderMock: WebLoaderProtocol {
    var delegate: WebLoaderDelegate?
    let brandedURL: URL

    init(brandedURL: URL) {
        self.brandedURL = brandedURL
    }

    var loadCalled: Bool = false
    func load() {
        loadCalled = true
    }
}

final class WebLoaderDelegateMock: WebLoaderDelegate {
    var didReceiveCalled: Bool = false
    var receivedMessage: WKScriptMessage?
    func didReceive(message: WKScriptMessage) {
        didReceiveCalled = true
        receivedMessage = message
    }
}
