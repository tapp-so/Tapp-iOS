import Foundation

struct CreateAffiliateURLRequest: Codable {
    private let tappToken: String
    private let bundleID: String
    private let mmp: Int
    private let influencer: String
    private let adGroup: String?
    private let creative: String?
    private let data: [String: String]?

    enum CodingKeys: String, CodingKey {
        case tappToken = "tapp_token"
        case bundleID = "bundle_id"
        case mmp
        case influencer
        case creative
        case adGroup = "adgroup"
        case data
    }

    init(tappToken: String,
         bundleID: String,
         mmp: Int,
         influencer: String,
         adGroup: String? = nil,
         creative: String? = nil,
         data: [String: String]?) {
        self.tappToken = tappToken
        self.bundleID = bundleID
        self.mmp = mmp
        self.influencer = influencer
        self.adGroup = adGroup
        self.creative = creative
        self.data = data
    }
}
