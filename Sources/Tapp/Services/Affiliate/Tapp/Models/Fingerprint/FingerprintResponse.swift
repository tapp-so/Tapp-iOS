import Foundation

struct FingerprintResponse: Codable {
    let fingerprint: String?
    let deeplink: URL?
    let error: Bool
}
