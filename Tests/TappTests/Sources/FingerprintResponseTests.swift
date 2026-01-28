import Foundation
import XCTest
@testable import Tapp

final class FingerprintResponseTests: XCTestCase {
    func testIsAlreadyVerified() {
        XCTAssertFalse(FingerprintResponse.response(hasErrorValue: false, error: false, hasMessage: false).isAlreadyVerified)
        XCTAssertFalse(FingerprintResponse.response(error: false, hasMessage: false).isAlreadyVerified)
        XCTAssertTrue(FingerprintResponse.response(error: false, hasMessage: true).isAlreadyVerified)
        XCTAssertFalse(FingerprintResponse.response(error: true, hasMessage: true).isAlreadyVerified)
        XCTAssertFalse(FingerprintResponse.response(error: true, hasMessage: false).isAlreadyVerified)
    }

    func testValidData() {
        let sut = FingerprintResponse.response(hasErrorValue: false, error: false, hasMessage: false, data: ["key1": nil, "key2": nil, "key3": "value3"])
        XCTAssertEqual(sut.validData, ["key3": "value3"])
    }
}

extension FingerprintResponse {
    static func response(hasErrorValue: Bool = true, error: Bool, hasMessage: Bool, data: [String: String?]? = nil) -> FingerprintResponse {
        let url = URL(string: "https://tapp.so")!
        let message: String? = hasMessage ? "already verified" : nil
        return FingerprintResponse(deeplink: url,
                                   tappURL: url,
                                   attributedTappURL: url,
                                   influencer: "influencer",
                                   data: data,
                                   deviceID: .init(id: "id1", active: true),
                                   error: hasErrorValue ? error: nil,
                                   message: message)
    }
}
