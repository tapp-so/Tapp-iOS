import Foundation
import TappNetworking

final class Dependencies {
    let keychainHelper: KeychainHelperProtocol
    let networkClient: NetworkClientProtocol
    let services: Services

    init(keychainHelper: KeychainHelperProtocol,
         networkClient: NetworkClientProtocol,
         services: Services) {
        self.keychainHelper = keychainHelper
        self.networkClient = networkClient
        self.services = services
    }
}

final class Services {
    let tappService: TappAffiliateServiceProtocol
    let webLoaderProvider: WebLoaderProviderProtocol

    init(tappService: TappAffiliateServiceProtocol,
         webLoaderProvider: WebLoaderProviderProtocol) {
        self.tappService = tappService
        self.webLoaderProvider = webLoaderProvider
    }
}

final class WebLoaderProvider: WebLoaderProviderProtocol {
    func make(brandedURL: URL) -> WebLoaderProtocol {
        return WebLoader(brandedURL: brandedURL)
    }
}

extension Dependencies {
    static var live: Dependencies {
        let keychainHelper: KeychainHelperProtocol = KeychainHelper.shared
        let networkClient: NetworkClientProtocol = NetworkClient(sessionConfiguration: SessionConfiguration(),
                                                                 keychainHelper: keychainHelper)
        let webLoaderProvider = WebLoaderProvider()
        let tappService: TappAffiliateServiceProtocol = TappAffiliateService(keychainHelper: keychainHelper,
                                                                             networkClient: networkClient,
                                                                             webLoaderProvider: webLoaderProvider)
        let services = Services(tappService: tappService, webLoaderProvider: webLoaderProvider)

        let dependencies = Dependencies(keychainHelper: keychainHelper,
                                        networkClient: networkClient,
                                        services: services)

        return dependencies
    }
}
