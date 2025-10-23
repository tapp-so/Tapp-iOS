import Foundation

struct SecretsRequest: Codable {
    private let tappToken: String
    private let bundleID: String
    private let mmp: Int

    enum CodingKeys: String, CodingKey {
        case tappToken = "tapp_token"
        case bundleID = "bundle_id"
        case mmp
    }

    init(tappToken: String, bundleID: String, mmp: Int) {
        self.tappToken = tappToken
        self.bundleID = bundleID
        self.mmp = mmp
    }
}

struct SecretsResponse: Codable {
    let secret: String
}
