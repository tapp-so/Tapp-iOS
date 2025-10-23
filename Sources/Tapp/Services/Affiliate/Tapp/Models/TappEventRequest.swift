import Foundation

struct TappEventRequest: Codable {
    private let tappToken: String
    private let bundleID: String
    private let eventName: String
    private let url: String?

    enum CodingKeys: String, CodingKey {
        case tappToken = "tapp_token"
        case bundleID = "bundle_id"
        case eventName = "event_name"
        case url = "event_url"
    }

    init(tappToken: String, bundleID: String, eventName: String, url: String?) {
        self.tappToken = tappToken
        self.bundleID = bundleID
        self.eventName = eventName
        self.url = url
    }
}
