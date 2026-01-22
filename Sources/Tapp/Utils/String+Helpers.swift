import Foundation

enum LogEvent {
    case didReceiveDeviceID(String)

    var value: String {
        switch self {
        case .didReceiveDeviceID(let string):
            return "Tapp Device ID: \(string)"
        }
    }

    func log(environment: Environment = .sandbox) {
        switch environment {
        case .sandbox:
            value.log(environment: environment)
        case .production:
            break
        }
    }
}

extension String {
    public static var empty: String {
        return ""
    }

    public static var emptyNSString: NSString {
        return String.empty as NSString
    }

    fileprivate func log(environment: Environment) {
        print("\(environment.log): \(self)")
    }
}

fileprivate extension Environment {
    var log: String {
        switch self {
        case .production:
            return "[Production]"
        case .sandbox:
            return "[Sandbox]"
        }
    }
}
