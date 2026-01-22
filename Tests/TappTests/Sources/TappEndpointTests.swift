import Foundation
import XCTest
@testable import Tapp

final class TappEndpointTests: XCTestCase {
    func testAPIPath() {
        XCTAssertEqual(APIPath.id.prefixInfluencer, "influencer/id")
        XCTAssertEqual(APIPath.id.prefixAdd, "add/id")
        XCTAssertEqual(String.emptyNSString, "")
    }

    func testHTTPMethod() {
        XCTAssertEqual(TappEndpoint.generateURL(affiliateURLRequest).httpMethod, .post)
        XCTAssertEqual(TappEndpoint.deeplink(impressionRequest).httpMethod, .post)
        XCTAssertEqual(TappEndpoint.secrets(secretsRequest).httpMethod, .post)
        XCTAssertEqual(TappEndpoint.tappEvent(eventRequest).httpMethod, .post)
        XCTAssertEqual(TappEndpoint.linkData(linkDataRequest).httpMethod, .post)
        XCTAssertEqual(TappEndpoint.fingerpint(fingerPrint).httpMethod, .post)
        XCTAssertEqual(TappEndpoint.device(deviceRequest).httpMethod, .post)
    }

    func testPath() {
        XCTAssertEqual(TappEndpoint.generateURL(affiliateURLRequest).path, APIPath.add.prefixInfluencer)
        XCTAssertEqual(TappEndpoint.deeplink(impressionRequest).path, APIPath.deeplink.rawValue)
        XCTAssertEqual(TappEndpoint.secrets(secretsRequest).path, APIPath.secrets.rawValue)
        XCTAssertEqual(TappEndpoint.tappEvent(eventRequest).path, APIPath.event.rawValue)
        XCTAssertEqual(TappEndpoint.linkData(linkDataRequest).path, APIPath.linkData.rawValue)
        XCTAssertEqual(TappEndpoint.fingerpint(fingerPrint).path, APIPath.fingerprint.rawValue)
        XCTAssertEqual(TappEndpoint.device(deviceRequest).path, APIPath.device.rawValue)
    }

    func testRequest() {
        XCTAssertNotNil(TappEndpoint.generateURL(affiliateURLRequest).request?.httpBody)
        XCTAssertNotNil(TappEndpoint.deeplink(impressionRequest).request?.httpBody)
        XCTAssertNotNil(TappEndpoint.secrets(secretsRequest).request?.httpBody)
        XCTAssertNotNil(TappEndpoint.tappEvent(eventRequest).request?.httpBody)
        XCTAssertNotNil(TappEndpoint.linkData(linkDataRequest).request?.httpBody)
        XCTAssertNotNil(TappEndpoint.fingerpint(fingerPrint).request?.httpBody)
        XCTAssertNotNil(TappEndpoint.device(deviceRequest).request?.httpBody)
    }
}

private extension TappEndpointTests {
    var affiliateURLRequest: CreateAffiliateURLRequest {
        return CreateAffiliateURLRequest(tappToken: tappToken, bundleID: bundleID, mmp: mmp, influencer: influencer, data: data)
    }

    var impressionRequest: ImpressionRequest {
        return ImpressionRequest(tappToken: tappToken, bundleID: bundleID, deepLink: url)
    }

    var secretsRequest: SecretsRequest {
        return SecretsRequest(tappToken: tappToken, bundleID: bundleID, mmp: mmp)
    }

    var eventRequest: TappEventRequest {
        return TappEventRequest(tappToken: tappToken, bundleID: bundleID, eventName: eventName, url: url.absoluteString, metadata: nil)
    }

    var linkDataRequest: TappLinkDataRequest {
        return TappLinkDataRequest(tappToken: tappToken, bundleID: bundleID, linkToken: linkToken)
    }

    var fingerPrint: Fingerprint {
        return Fingerprint.generate(tappToken: tappToken, webBody: nil, deviceID: nil)
    }

    var deviceRequest: DeviceRequest {
        return DeviceRequest(tappToken: tappToken, bundleID: bundleID, mmp: mmp, deviceID: nil)
    }

    var tappToken: String {
        return "tappToken"
    }

    var bundleID: String {
        return "bundleID"
    }

    var mmp: Int {
        return 3
    }

    var influencer: String {
        return "influencer"
    }

    var data: [String: String]? {
        return nil
    }

    var url: URL {
        return URL(string: "https://tapp.so")!
    }

    var eventName: String {
        return "eventName"
    }

    var linkToken: String {
        return "linkToken"
    }
}

final class GeneratedURLResponseTests: XCTestCase {
    func testInit() {
        let url = URL(string: "https://tapp.so")!
        let sut = GeneratedURLResponse(url: url)
        XCTAssertEqual(sut.url, url)
        XCTAssertEqual(GeneratedURLResponse.CodingKeys.url.rawValue, "influencer_url")
    }
}
