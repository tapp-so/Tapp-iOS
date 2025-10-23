import Foundation

@objc
public final class GeneratedURLResponse: NSObject, Codable {

    @objc
    public let url: URL

    init(url: URL) {
        self.url = url
    }

    enum CodingKeys: String, CodingKey {
        case url = "influencer_url"
    }
}
