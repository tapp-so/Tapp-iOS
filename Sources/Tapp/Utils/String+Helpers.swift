import Foundation

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
