import Foundation
import WebKit

final class WebLoader: NSObject {
    let webView: WKWebView

    private enum MessageName: String {
        case deviceInfo
    }

    override init() {
        let preferences = WKWebpagePreferences()
        preferences.preferredContentMode = .recommended

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences

        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()

        configuration.userContentController.add(self, name: MessageName.deviceInfo.rawValue)
    }
}

extension WebLoader: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let name = MessageName(rawValue: message.name) else { return }
        switch name {
        case .deviceInfo:
            break
        }
    }

    private func handleDeviceInfo(_ message: WKScriptMessage) {
        //Send  to backend 
    }
}
