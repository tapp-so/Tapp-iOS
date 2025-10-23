import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@objc
public final class FingerprintTestConfiguration: NSObject {
    let isTestingFingerprints: Bool
    let fingerprintOperationResult: Bool

    @objc
    public init(isTestingFingerprints: Bool, fingerprintOperationResult: Bool) {
        self.isTestingFingerprints = isTestingFingerprints
        self.fingerprintOperationResult = fingerprintOperationResult
        super.init()
    }
}

struct Fingerprint: Codable {
    let fp: Bool?
    let tappToken: String
    let screenResolution: String
    let language: String
    let region: String
    let locale: String
    let calendar: String
    let numberingSystem: String?
    let defaultDateFormat: String
    let timezone: String
    let orientation: String
    let platform: String
    let userAgent: String
    let timestamp: Int64

    static func generate(tappToken: String, testConfiguration: FingerprintTestConfiguration?) -> Fingerprint {

        var isSuccess: Bool?
        if let testConfiguration, testConfiguration.isTestingFingerprints {
            isSuccess = testConfiguration.fingerprintOperationResult
        }

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

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        return Fingerprint(fp: isSuccess,
                           tappToken: tappToken,
                           screenResolution: screenResolution,
                           language: language,
                           region: region,
                           locale: language,
                           calendar: calendar,
                           numberingSystem: numberingSystem,
                           defaultDateFormat: defaultDateFormat,
                           timezone: timezone,
                           orientation: orientation,
                           platform: platform,
                           userAgent: userAgent,
                           timestamp: timestamp
        )
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
