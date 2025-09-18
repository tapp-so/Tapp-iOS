import Foundation

@objc
public protocol TappDelegate: AnyObject {
    @objc optional func didOpenApplication(with data: TappDeferredLinkData)
    @objc optional func didFailResolvingURL(url: URL, error: Error)
}

@objc
public final class TappDeferredLinkData: NSObject {

    @objc public let tappURL: URL
    @objc public let attributedTappURL: URL
    @objc public let influencer: String
    @objc public let data: [String: String]?
    @objc public let isFirstSession: Bool

    init(tappURL: URL, attributedTappURL: URL, influencer: String, data: [String : String]?, isFirstSession: Bool) {
        self.tappURL = tappURL
        self.attributedTappURL = attributedTappURL
        self.influencer = influencer
        self.data = data
        self.isFirstSession = isFirstSession
        super.init()
    }

    convenience init(dto: TappDeferredLinkDataDTO, isFirstSession: Bool) {
        self.init(tappURL: dto.tappURL,
                  attributedTappURL: dto.attributedTappURL,
                  influencer: dto.influencer,
                  data: dto.data,
                  isFirstSession: isFirstSession)
    }
}

struct TappDeferredLinkDataDTO: Codable {
    let tappURL: URL
    let attributedTappURL: URL
    let influencer: String
    let data: [String: String]?

    enum CodingKeys: String, CodingKey {
        case tappURL = "tapp_url"
        case attributedTappURL = "attr_tapp_url"
        case influencer = "influencer"
        case data
    }
}
