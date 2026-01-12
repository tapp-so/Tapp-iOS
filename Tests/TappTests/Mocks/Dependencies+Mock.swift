import Foundation
@testable import Tapp

final class DependenciesHelper {
    let keychainHelper: KeychainHelperMock = .init()
    let networkClient: NetworkClientMock = .init()
    let webLoaderProvider: WebLoaderProviderMock = .init()
    let tappAffiliateService: TappAffiliateServiceMock = .init()

    var dependencies: Dependencies {
        let services = Services(tappService: tappAffiliateService, webLoaderProvider: webLoaderProvider)
        return Dependencies(keychainHelper: keychainHelper,
                            networkClient: networkClient,
                            services: services)
    }
}
