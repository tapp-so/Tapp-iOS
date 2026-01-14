import Foundation
import XCTest
import TappNetworking
@testable import Tapp

final class DependenciesTests: XCTestCase {
    func testInstances() {
        let sut = Dependencies.live
        XCTAssertNotNil(sut.keychainHelper as? KeychainHelper)
        XCTAssertNotNil(sut.networkClient as? NetworkClient)

        XCTAssertNotNil(sut.services.webLoaderProvider as? WebLoaderProvider)
        XCTAssertNotNil(sut.services.webLoaderProvider.make(brandedURL: URL(string: "https://tapp.so")!) as? WebLoader)
        XCTAssertNotNil(sut.services.tappService as? TappAffiliateService)
    }
}
