import Foundation
import XCTest
@testable import Tapp

final class TCResponseTests: XCTestCase {
    func testIsAlreadyVerified() {
        XCTAssertFalse(TCResponse.response(hasErrorValue: false, error: false, hasMessage: false).isAlreadyVerified)
        XCTAssertFalse(TCResponse.response(error: true, hasMessage: false).isAlreadyVerified)
        XCTAssertTrue(TCResponse.response(error: false, hasMessage: true).isAlreadyVerified)
        XCTAssertFalse(TCResponse.response(error: true, hasMessage: true).isAlreadyVerified)
    }

    func testValidData() {
        let sut = TCResponse.response(hasErrorValue: false, error: false, hasMessage: false, data: ["key1": nil, "key2": nil, "key3": "value3"])
        XCTAssertEqual(sut.validData, ["key3": "value3"])
    }
}

extension TCResponse {
    static func response(hasErrorValue: Bool = true, error: Bool, hasMessage: Bool, data: [String: String?]? = nil) -> TCResponse {
        let url = URL(string: "https://tapp.so")!
        let message: String? = hasMessage ? "already verified" : nil
        return TCResponse(deeplink: url,
                          tappURL: url,
                          attributedTappURL: url,
                          influencer: "influencer",
                          data: data,
                          deviceID: .init(id: "id1", active: true),
                          error: hasErrorValue ? error: nil,
                          message: message)
    }
}
