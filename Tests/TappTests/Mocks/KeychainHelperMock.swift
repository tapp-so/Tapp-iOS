import Foundation
import TappNetworking

final class KeychainHelperMock: KeychainHelperProtocol {
    var saveCalledCount: Int = 0
    func save(configuration: TappConfiguration) {
        saveCalledCount += 1
        configObject = configuration
    }

    var setBundleID: String?
    func set(bundleID: String?) {
        setBundleID = bundleID
    }

    var setEnvironment: Environment = .sandbox
    func set(environment: Environment) {
        setEnvironment = environment
    }

    var configObject: TappConfiguration?
    var config: TappConfiguration? {
        return configObject
    }

    var hasConfig: Bool {
        return config != nil
    }
}
