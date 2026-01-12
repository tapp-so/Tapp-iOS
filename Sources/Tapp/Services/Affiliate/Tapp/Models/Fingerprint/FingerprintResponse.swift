import Foundation

public struct FingerprintResponse: Codable, Equatable {
    let deeplink: URL?
    let tappURL: URL?
    let attributedTappURL: URL?
    let influencer: String?
    let data: [String: String?]?
    let deviceID: DeviceID?
    let error: Bool?
    let message: String?

    struct DeviceID: Codable, Equatable {
        let id: String
        let active: Bool
    }

    enum Message: String {
        case alreadyVerified = "Already verified"
    }

    enum CodingKeys: String, CodingKey {
        case tappURL = "tapp_url"
        case attributedTappURL = "attr_tapp_url"
        case influencer = "influencer"
        case data
        case deeplink
        case error
        case deviceID = "device_id"
        case message
    }
}

extension FingerprintResponse {
    var isAlreadyVerified: Bool {
        guard let error else { return false }
        if error == false {
            if message == nil {
                return true
            }
        } else {
            return false
        }
        return false
    }

    var validData: [String: String]? {
        guard let data else { return nil }
        var dict: [String: String] = [:]
        for key in data.keys {
            if let value = data[key] {
                dict[key] = value
            }
        }
        return dict
    }
}
