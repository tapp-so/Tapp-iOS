import Foundation

struct ImpressionRequest: Codable {
    private let tappToken: String
    private let bundleID: String
    private let deepLink: URL

    enum CodingKeys: String, CodingKey {
        case tappToken = "tapp_token"
        case bundleID = "bundle_id"
        case deepLink = "deeplink"
    }

    init(tappToken: String, bundleID: String, deepLink: URL) {
        self.tappToken = tappToken
        self.bundleID = bundleID
        self.deepLink = deepLink
    }
}
