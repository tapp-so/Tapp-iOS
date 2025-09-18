//
//  Dependencies.swift
//
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

    init(tappService: TappAffiliateServiceProtocol) {
        self.tappService = tappService
    }
}

extension Dependencies {
    static var live: Dependencies {
        let keychainHelper: KeychainHelperProtocol = KeychainHelper.shared
        let networkClient: NetworkClientProtocol = NetworkClient(sessionConfiguration: SessionConfiguration(),
                                                                 keychainHelper: keychainHelper)

        let tappService: TappAffiliateServiceProtocol = TappAffiliateService(keychainHelper: keychainHelper,
                                                                             networkClient: networkClient)
        let services = Services(tappService: tappService)

        let dependencies = Dependencies(keychainHelper: keychainHelper,
                                        networkClient: networkClient,
                                        services: services)

        return dependencies
    }
}
