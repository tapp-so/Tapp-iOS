import Foundation

struct TappLinkDataRequest: Codable {
    let tappToken: String
    let bundleID: String
    let linkToken: String

    enum CodingKeys: String, CodingKey {
        case tappToken = "tapp_token"
        case bundleID = "bundle_id"
        case linkToken = "link_token"
    }

    init(tappToken: String, bundleID: String, linkToken: String) {
        self.tappToken = tappToken
        self.bundleID = bundleID
        self.linkToken = linkToken
    }
}
