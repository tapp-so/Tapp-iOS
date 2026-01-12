import Foundation
import WebKit

protocol WebLoaderDelegate: AnyObject {
    func didReceive(message: WKScriptMessage)
}

protocol WebLoaderProtocol: AnyObject {
    var delegate: WebLoaderDelegate? { get set }
    func load()
}

protocol WebLoaderProviderProtocol: AnyObject {
    func make(brandedURL: URL) -> WebLoaderProtocol
}

final class WebLoader: NSObject, WebLoaderProtocol {
    let webView: WKWebView
    let brandedURL: URL
    var delegate: WebLoaderDelegate?

    private enum MessageName: String {
        case deviceInfo
    }

    init(brandedURL: URL) {
        let preferences = WKWebpagePreferences()
        preferences.preferredContentMode = .recommended

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences

        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.brandedURL = brandedURL
        super.init()

        configuration.userContentController.add(self, name: MessageName.deviceInfo.rawValue)
    }

    func load() {
        webView.load(URLRequest(url: brandedURL))
    }
}

extension WebLoader: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let name = MessageName(rawValue: message.name) else { return }
        switch name {
        case .deviceInfo:
            delegate?.didReceive(message: message)
        }
    }
}
