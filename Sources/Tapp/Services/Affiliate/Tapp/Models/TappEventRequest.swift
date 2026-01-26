import Foundation

struct TappEventRequest: Encodable {
    private let tappToken: String
    private let bundleID: String
    private let eventName: String
    private let os: TappOS = .ios
    private let url: String?
    private let metadata: [String: Encodable]?

    enum CodingKeys: String, CodingKey {
        case tappToken = "tapp_token"
        case bundleID = "bundle_id"
        case eventName = "event_name"
        case url = "event_url"
        case os
        case metadata
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.tappToken, forKey: .tappToken)
        try container.encode(self.bundleID, forKey: .bundleID)
        try container.encode(self.eventName, forKey: .eventName)
        try container.encodeIfPresent(self.url, forKey: .url)
        try container.encode(self.os, forKey: .os)

        if let metadata {
            var dict: [String: AnyEncodable] = [:]
            for (key, value) in metadata {
                dict[key] = AnyEncodable(value)
            }
            try container.encode(dict, forKey: .metadata)
        }
    }

    init(tappToken: String, bundleID: String, eventName: String, url: String?, metadata: [String: Encodable]?) {
        self.tappToken = tappToken
        self.bundleID = bundleID
        self.eventName = eventName
        self.url = url
        self.metadata = metadata
    }
}

struct AnyEncodable: Encodable {
  private let encodable: any Encodable

  public init(_ encodable: any Encodable) {
    self.encodable = encodable
  }

  public func encode(to encoder: any Encoder) throws {
    try encodable.encode(to: encoder)
  }
}
