import Foundation
import XCTest
import WebKit
@testable import Tapp

final class WebLoaderTests: XCTestCase {
    var delegate: WebLoaderDelegateMock!
    var sut: WebLoader!

    override func setUp() {
        delegate = .init()
        sut = .init(brandedURL: URL(string: "https://tapp.so")!)
        sut.delegate = delegate
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        delegate = nil
        super.tearDown()
    }

    func testInit() {
        let configuration = sut.webView.configuration
        XCTAssertEqual(configuration.defaultWebpagePreferences.preferredContentMode, .recommended)
        
        XCTAssertNotNil(sut.webView.configuration)
    }

    func testScriptMessageHandlerWithValidMessageName() {
        let message = TestScriptMessage(overrideBody: "body", overrideName: "deviceInfo")
        sut.userContentController(.init(), didReceive: message)
        XCTAssertTrue(delegate.didReceiveCalled)
    }

    func testScriptMessageHandlerWithInvalidMessageName() {
        let message = TestScriptMessage(overrideBody: "body", overrideName: "test")
        sut.userContentController(.init(), didReceive: message)
        XCTAssertFalse(delegate.didReceiveCalled)
    }
}
