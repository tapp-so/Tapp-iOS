import Foundation

final class GenerateURLRequest: NSObject, Codable {
    let influencer: String
    let adGroup: String?
    let creative: String?
    let mmp: Affiliate
    let data: [String: String]?

    enum CodingKeys: String, CodingKey {
        case influencer
        case mmp
        case creative
        case adGroup = "adgroup"
        case data
    }

    init(influencer: String, adGroup: String? = nil, creative: String? = nil, mmp: Affiliate, data: [String: String]?) {
        self.influencer = influencer
        self.adGroup = adGroup
        self.creative = creative
        self.mmp = mmp
        self.data = data
        super.init()
    }
}
