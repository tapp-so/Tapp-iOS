import Foundation
import TappNetworking

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct Fingerprint: Codable {
    let tappToken: String
    let webview: String?
    let screenResolution: String
    let deviceName: String
    let language: String
    let region: String
    let locale: String 
    let calendar: String
    let numberingSystem: String?
    let defaultDateFormat: String
    let timezone: String
    let platform: String
    let userAgent: String
    let timestamp: Int64
    let bundleID: String?
    let deviceID: String?


    enum CodingKeys: String, CodingKey {
        case tappToken = "tapp_token"
        case webview

        case screenResolution
        case deviceName
        case language
        case region
        case locale
        case calendar
        case numberingSystem
        case defaultDateFormat
        case timezone
        case platform
        case userAgent
        case timestamp
        case bundleID = "bundle_id"
        case deviceID = "device_id"
    }

    static func generate(tappToken: String, webBody: String?, deviceID: String?) -> Fingerprint {
        let screenResolution: String = {
            #if os(iOS)
            let screen = UIScreen.main
            let scale = screen.scale
            let width = Int(screen.bounds.width * scale)
            let height = Int(screen.bounds.height * scale)
            return "\(width)x\(height)"
            #elseif os(macOS)
            if let screen = NSScreen.main {
                let scale = screen.backingScaleFactor
                let width = Int(screen.frame.width * scale)
                let height = Int(screen.frame.height * scale)
                return "\(width)x\(height)"
            } else {
                return "unknown"
            }
            #endif
        }()

        let deviceName: String = {
            #if os(iOS)
            return UIDevice.current.tp_modelIdentifier
            #elseif os(macOS)
            return ProcessInfo.processInfo.tp_modelIdentifier
            #endif
        }()

        let locale = Locale.current
        let language = locale.identifier.replacingOccurrences(of: "_", with: "-")
        let region = locale.regionCode ?? "unknown"

        var numberingSystem = "latn"

        if #available(iOS 16, *) {
            numberingSystem = locale.numberingSystem.identifier
        }
        let calendar = locale.calendar.identifier.debugDescription
        let defaultDateFormat = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let timezone = TimeZone.current.identifier

        let orientation = UIDeviceOrientation.stringValue

        #if os(iOS)
        let platform = "iOS"
        #else
        let platform = "macOS"
        #endif

        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let userAgent = "App/\(bundleID)"

        let timestamp = Int64(Date().timeIntervalSince1970)

        return Fingerprint(tappToken: tappToken,
                           webview: webBody,
                           screenResolution: screenResolution,
                           deviceName: deviceName,
                           language: language,
                           region: region,
                           locale: language,
                           calendar: calendar,
                           numberingSystem: numberingSystem,
                           defaultDateFormat: defaultDateFormat,
                           timezone: timezone,
                           platform: platform,
                           userAgent: userAgent,
                           timestamp: timestamp,
                           bundleID: bundleID,
                           deviceID: deviceID)
    }
}

private extension UIDeviceOrientation {
    static var stringValue: String {
        #if os(iOS)
        switch UIDevice.current.orientation {
            case .portrait: return "portrait"
            case .portraitUpsideDown: return "portraitUpsideDown"
            case .landscapeLeft: return "landscapeLeft"
            case .landscapeRight: return "landscapeRight"
            case .faceUp: return "faceUp"
            case .faceDown: return "faceDown"
            default: return "unknown"
        }
        #else
        return "macos"
        #endif
    }
}

private extension UIDevice {
    var tp_modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }
}

private extension ProcessInfo {
    var tp_modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }
}
