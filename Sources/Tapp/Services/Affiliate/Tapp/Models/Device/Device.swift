import Foundation

struct DeviceRequest: Codable {
    let tappToken: String
    let bundleID: String
    let mmp: Int
    let deviceID: String?

    enum CodingKeys: String, CodingKey {
        case tappToken = "tapp_token"
        case bundleID = "bundle_id"
        case mmp
        case deviceID = "device_id"
    }
}

struct DeviceResponse: Codable {
    let error: Bool
    let device: Device
    let message: String?

    enum CodingKeys: String, CodingKey {
        case error
        case device = "device_id"
        case message
    }
}

struct Device: Codable {
    let id: String
    let active: Bool
}
