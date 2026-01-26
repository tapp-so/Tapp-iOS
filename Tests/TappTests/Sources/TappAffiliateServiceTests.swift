import Foundation
import XCTest
import TappNetworking
import WebKit
@testable import Tapp

final class TappAffiliateServiceTests: XCTestCase {
    var dependenciesHelper: DependenciesHelper!
    var sut: TappAffiliateService!
    var delegate: AffiliateServiceDelegateMock!

    override func setUp() {
        dependenciesHelper = .init()
        delegate = .init()
        sut = TappAffiliateService(keychainHelper: dependenciesHelper.keychainHelper,
                                   networkClient: dependenciesHelper.networkClient,
                                   webLoaderProvider: dependenciesHelper.webLoaderProvider)
        sut.delegate = delegate

        super.setUp()
    }

    override func tearDown() {
        dependenciesHelper = nil
        sut = nil
        super.tearDown()
    }

    func testInitializeWithMissingConfig() {
        sut.initialize(environment: .sandbox, brandedURL: url) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .invalidData:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testInitializeWithValidConfigSandbox() {
        let env = Environment.sandbox
        dependenciesHelper.keychainHelper.configObject = config(env: env)

        let expectation = expectation(description: "testInitializeWithValidConfigSandbox")

        let fetchDeviceRequest = self.fetchDeviceRequest(env: env)
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[fetchDeviceRequest.url!.absoluteString] = data(codable: deviceResponse(active: false))

        XCTAssertFalse(dependenciesHelper.keychainHelper.config!.isAlreadyVerified)

        sut.initialize(environment: .sandbox, brandedURL: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(fetchDeviceCalled(env: env))
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 2)
    }

    func testInitializeWithValidConfigProduction() {
        let env = Environment.production
        dependenciesHelper.keychainHelper.configObject = config(env: env)

        let expectation = expectation(description: "testInitializeWithValidConfigProduction")

        let fetchDeviceRequest = self.fetchDeviceRequest(env: env)
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[fetchDeviceRequest.url!.absoluteString] = data(codable: deviceResponse(active: false))

        XCTAssertFalse(dependenciesHelper.keychainHelper.config!.isAlreadyVerified)

        sut.initialize(environment: .sandbox, brandedURL: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(fetchDeviceCalled(env: env))
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 1)
    }

    func testInitializeWithValidConfigProductionWithMissingDeviceID() {
        let env = Environment.production
        let config = config(env: env)

        dependenciesHelper.keychainHelper.configObject = config

        let expectation = expectation(description: "testInitializeWithValidConfigProductionWithExistingDeviceID")

        XCTAssertFalse(dependenciesHelper.keychainHelper.config!.isAlreadyVerified)

        let deviceRequestObject = DeviceRequest(tappToken: tappToken, bundleID: bundleID, mmp: 3, deviceID: nil)
        let deviceEndpoint = TappEndpoint.device(deviceRequestObject)
        let deviceRequest = deviceEndpoint.request!
        let deviceResponse = DeviceResponse(error: false, device: Device(id: "123456", active: true), message: nil)

        dependenciesHelper.networkClient.executeAuthenticatedResponseData[deviceRequest.url!.absoluteString] = data(codable: deviceResponse)

        sut.initialize(environment: env, brandedURL: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(fetchDeviceCalled(env: env))
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 1)
        XCTAssertNotNil(sut.webLoader)

        guard let webLoader = sut.webLoader as? WebLoaderMock else {
            XCTFail()
            return
        }

        XCTAssertTrue(webLoader.loadCalled)

        let fingerprint = Fingerprint.generate(tappToken: config.tappToken,
                                               webBody: message.body as? String,
                                               deviceID: config.deviceID)
        let endpoint = TappEndpoint.fingerpint(fingerprint)
        let fingerprintRequest = endpoint.request!
        let fingerprintResponse = fingerprintResponse(error: false, message: nil, active: true)
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[fingerprintRequest.url!.absoluteString] = data(codable: fingerprintResponse)

        sut.didReceive(message: message)

        XCTAssertNotNil(dependenciesHelper.networkClient.executeAuthenticatedRequests[fingerprintRequest.url!.absoluteString])
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 2)
        XCTAssertTrue(delegate.didReceiveCalled)
        XCTAssertEqual(delegate.receivedResponse, fingerprintResponse)
    }

    func testInitializeWithValidConfigProductionWithExistingDeviceID() {
        let env = Environment.production
        let config = config(env: env)
        config.set(deviceID: "id1")

        dependenciesHelper.keychainHelper.configObject = config

        let expectation = expectation(description: "testInitializeWithValidConfigProductionWithExistingDeviceID")

        XCTAssertFalse(dependenciesHelper.keychainHelper.config!.isAlreadyVerified)

        sut.initialize(environment: env, brandedURL: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(fetchDeviceCalled(env: env))
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 1)
        XCTAssertNotNil(sut.webLoader)

        guard let webLoader = sut.webLoader as? WebLoaderMock else {
            XCTFail()
            return
        }

        XCTAssertTrue(webLoader.loadCalled)

        let fingerprint = Fingerprint.generate(tappToken: config.tappToken,
                                               webBody: message.body as? String,
                                               deviceID: config.deviceID)
        let endpoint = TappEndpoint.fingerpint(fingerprint)
        let fingerprintRequest = endpoint.request!
        let fingerprintResponse = fingerprintResponse(error: false, message: nil, active: true)
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[fingerprintRequest.url!.absoluteString] = data(codable: fingerprintResponse)

        sut.didReceive(message: message)

        XCTAssertNotNil(dependenciesHelper.networkClient.executeAuthenticatedRequests[fingerprintRequest.url!.absoluteString])
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 2)
        XCTAssertTrue(delegate.didReceiveCalled)
        XCTAssertEqual(delegate.receivedResponse, fingerprintResponse)
    }

    func testInitializeWithValidConfigProductionWithExistingDeviceIDWithOriginURL() {
        let env = Environment.production
        let config = config(env: env)
        config.set(deviceID: "id1")
        config.set(originURL: url)

        dependenciesHelper.keychainHelper.configObject = config

        let expectation = expectation(description: "testInitializeWithValidConfigProductionWithExistingDeviceID")

        XCTAssertFalse(dependenciesHelper.keychainHelper.config!.isAlreadyVerified)

        sut.initialize(environment: .sandbox, brandedURL: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(fetchDeviceCalled(env: env))
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 1)
        XCTAssertNil(sut.webLoader)
    }

    func testGenerateURLWithMissingConfig() {
        sut.url(request: generateURLRequest()) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .invalidData:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testGenerateURLWithValidConfig() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)
        let expectation = expectation(description: "testGenerateURLWithValidConfig")

        let object = createAffiliateURLRequest
        let endpoint = TappEndpoint.generateURL(object)
        let request = endpoint.request(encodable: object)
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[request!.url!.absoluteString] = data(codable: generateURLResponse())

        sut.url(request: generateURLRequest()) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.url.absoluteString, "https://tapp.so")
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testGenerateURLWithValidConfigDecodingError() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)
        let expectation = expectation(description: "testGenerateURLWithValidConfig")

        let object = createAffiliateURLRequest
        let endpoint = TappEndpoint.generateURL(object)
        let request = endpoint.request(encodable: object)
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[request!.url!.absoluteString] = Data()

        sut.url(request: generateURLRequest()) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappAffiliateServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .decodingError:
                    break
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testGenerateURLWithValidConfigServiceError() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)
        let expectation = expectation(description: "testGenerateURLWithValidConfig")

        dependenciesHelper.networkClient.executeAuthenticatedError = TappAffiliateServiceError.undefined

        sut.url(request: generateURLRequest()) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappAffiliateServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .undefined:
                    break
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testHandleCallbackError() {
        sut.handleCallback(with: .empty) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? ResolvedURLError else {
                    XCTFail()
                    return
                }
                switch err {
                case .cannotResolveURL:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testHandleCallbackSuccess() {
        sut.handleCallback(with: "https://tapp.so") { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
        }
    }

    func testHandleImpressionMissingConfig() {
        sut.handleImpression(url: url) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .invalidData:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testHandleImpressionSuccess() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)

        let expectation = expectation(description: "testHandleImpressionSuccess")
        let object = impressionRequest
        let endpoint = TappEndpoint.deeplink(object)
        let request = endpoint.request(encodable: object)!
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[request.url!.absoluteString] = Data()

        sut.handleImpression(url: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleImpressionFailure() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)

        let expectation = expectation(description: "testHandleImpressionFailure")
        dependenciesHelper.networkClient.executeAuthenticatedError = TappTestsError.undefined

        sut.handleImpression(url: url) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappTestsError else {
                    XCTFail()
                    return
                }
                switch err {
                case .undefined:
                    break
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testSecretsMissingConfig() {
        _ = sut.secrets(affiliate: .tapp) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }

                switch err {
                case .invalidData:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testSecretsSuccess() {
        let config = self.config(env: .sandbox)
        dependenciesHelper.keychainHelper.configObject = config
        let endpoint = TappEndpoint.secrets(secretsRequest)
        let request = endpoint.request(encodable: secretsRequest)!
        let expectation = expectation(description: "testSecretsMissingSuccess")
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[request.url!.absoluteString] = data(codable: secretsResponse)
        _ = sut.secrets(affiliate: .tapp) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.brandedURL, self.url)
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertNotNil(dependenciesHelper.networkClient.executeAuthenticatedRequests[request.url!.absoluteString])
    }

    func testSecretsServiceError() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)
        dependenciesHelper.networkClient.executeAuthenticatedError = TappServiceError.invalidID
        _ = sut.secrets(affiliate: .tapp) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }

                switch err {
                case .invalidID:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testSecretsDecodingError() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)
        let endpoint = TappEndpoint.secrets(secretsRequest)
        let request = endpoint.request(encodable: secretsRequest)!
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[request.url!.absoluteString] = Data()
        _ = sut.secrets(affiliate: .tapp) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappAffiliateServiceError else {
                    XCTFail()
                    return
                }

                switch err {
                case .decodingError:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testSendTappEventMissingConfig() {
        sut.sendTappEvent(event: event) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .invalidData:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testSendTappEventSuccess() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)
        dependenciesHelper.networkClient.executeAuthenticatedError = TappTestsError.undefined

        sut.sendTappEvent(event: event) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappTestsError else {
                    XCTFail()
                    return
                }
                switch err {
                case .undefined:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testSendTappEventServiceError() {
        dependenciesHelper.keychainHelper.configObject = config(env: .sandbox)
        let object = tappEventRequest
        let endpoint = TappEndpoint.tappEvent(object)
        let request = endpoint.request(encodable: object)!
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[request.url!.absoluteString] = Data()

        sut.sendTappEvent(event: event) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
        }
    }

    func testShouldProcess() {
        XCTAssertTrue(sut.shouldProcess(url: URL(string: "https://tapp.so")!))
        XCTAssertFalse(sut.shouldProcess(url: URL(string: "https://google.com")!))
    }

    func testLinkDataWithForAdjustSuccess() {
        XCTAssertTrue(dependenciesHelper.networkClient.executeAuthenticatedRequests.isEmpty)
        let config = self.config(env: .sandbox, affiliate: .adjust)
        let url = URL(string: "https://tapp.so?adj_t=1234")!
        dependenciesHelper.keychainHelper.configObject = config

        let object = linkDataRequest()
        let endpoint = TappEndpoint.linkData(object)
        let request = endpoint.request!
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[request.url!.absoluteString] = data(codable: linkDataResponse())

        let expectation = expectation(description: "testLinkDataWithForAdjustSuccess")
        sut.fetchLinkData(for: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        XCTAssertFalse(dependenciesHelper.networkClient.executeAuthenticatedRequests.isEmpty)
    }

    func testLinkDataWithForAdjustFailure() {
        let config = self.config(env: .sandbox, affiliate: .adjust)
        let url = URL(string: "https://tapp.so?adj_b=1234")!
        dependenciesHelper.keychainHelper.configObject = config

        let expectation = expectation(description: "testLinkDataWithForAdjustFailure")
        sut.fetchLinkData(for: url) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure:
                break
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(dependenciesHelper.networkClient.executeAuthenticatedRequests.isEmpty)
    }

    func testLinkDataWithForTappSuccess() {
        XCTAssertTrue(dependenciesHelper.networkClient.executeAuthenticatedRequests.isEmpty)
        let config = self.config(env: .sandbox, affiliate: .tapp)
        let url = URL(string: "https://tapp.so?t=1234")!
        dependenciesHelper.keychainHelper.configObject = config

        let object = linkDataRequest()
        let endpoint = TappEndpoint.linkData(object)
        let request = endpoint.request!
        dependenciesHelper.networkClient.executeAuthenticatedResponseData[request.url!.absoluteString] = data(codable: linkDataResponse())

        let expectation = expectation(description: "testLinkDataWithForTappSuccess")
        sut.fetchLinkData(for: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        XCTAssertFalse(dependenciesHelper.networkClient.executeAuthenticatedRequests.isEmpty)
    }

    func testLinkDataWithForTappFailure() {
        let config = self.config(env: .sandbox, affiliate: .tapp)
        let url = URL(string: "https://tapp.so?adj_b=1234")!
        dependenciesHelper.keychainHelper.configObject = config

        let expectation = expectation(description: "testLinkDataWithForTappFailure")
        sut.fetchLinkData(for: url) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure:
                break
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(dependenciesHelper.networkClient.executeAuthenticatedRequests.isEmpty)
    }

    func testLinkDataWithExistingIncompleteData() {
        let config = self.config(env: .sandbox)
        config.set(originURL: url)
        config.set(originAttributedTappURL: url)
        config.set(originData: ["key": "value"])
        dependenciesHelper.keychainHelper.configObject = config

        let expectation = expectation(description: "testLinkDataWithExistingIncompleteData")
        sut.fetchLinkData(for: url) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .invalidURL:
                    break
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(dependenciesHelper.networkClient.executeAuthenticatedRequests.isEmpty)
    }

    func testDeferredLinkDataDTODecoding() {
        let json = """
            {
                "error": false,
                "tapp_url": "https://test.staging.tapp.so/test",
                "attr_tapp_url": "https://test.staging.tapp.so/test?param1=value1a&param2=value2a",
                "influencer": "test",
                "data": {
                    "param1": "value1a",
                    "param2": "value2a",
                    "param3": null,
                    "param4": null
                }
            }
            """
        guard let data = json.data(using: .utf8) else {
            XCTFail()
            return
        }

        let decoder = JSONDecoder()
        do {
            let dto = try decoder.decode(TappDeferredLinkDataDTO.self, from: data)
            XCTAssertEqual(dto.data, ["param1": "value1a", "param2": "value2a"])
        } catch {
            XCTFail()
        }
    }
}

private extension TappAffiliateServiceTests {
    var event: TappEvent {
        return TappEvent(eventAction: .custom("test"))
    }

    var url: URL {
        return URL(string: "https://tapp.so")!
    }

    func config(env: Environment, affiliate: Affiliate? = nil) -> TappConfiguration {
        return TappConfiguration(authToken: "authToken123",
                                 env: env,
                                 tappToken: tappToken,
                                 affiliate: affiliate ?? .tapp,
                                 bundleID: "bundleID")
    }

    var tappToken: String {
        return "tappToken123"
    }

    var bundleID: String {
        return "bundleID123"
    }

    var influencer: String {
        return "influencer"
    }

    var tappEventRequest: TappEventRequest {
        return TappEventRequest(tappToken: tappToken, bundleID: bundleID, eventName: event.eventAction.name, url: url.absoluteString, metadata: nil)
    }

    var secretsRequest: SecretsRequest {
        return SecretsRequest(tappToken: tappToken, bundleID: bundleID, mmp: 3)
    }

    var secretsResponse: SecretsResponse {
        return SecretsResponse(secret: "secret", brandedURL: url)
    }

    var impressionRequest: ImpressionRequest {
        return ImpressionRequest(tappToken: tappToken, bundleID: bundleID, deepLink: url)
    }

    var createAffiliateURLRequest: CreateAffiliateURLRequest {
        let config = config(env: .sandbox)
        return CreateAffiliateURLRequest(tappToken: config.tappToken, bundleID: bundleID, mmp: 3, influencer: influencer, data: ["test": "test"])
    }

    func generateURLRequest(inf: String? = nil, adgroup: String? = nil, creative: String? = nil) -> GenerateURLRequest {
        return GenerateURLRequest(influencer: inf ?? influencer,
                                  adGroup: adgroup,
                                  creative: creative,
                                  mmp: .tapp,
                                  data: ["test": "test"])
    }

    func generateURLResponse() -> GeneratedURLResponse {
        return GeneratedURLResponse(url: url)
    }

    func linkDataRequest() -> TappLinkDataRequest {
        return TappLinkDataRequest(tappToken: tappToken, bundleID: bundleID, linkToken: "1234")
    }

    func linkDataResponse() -> TappDeferredLinkDataDTO {
        return TappDeferredLinkDataDTO(tappURL: url, attributedTappURL: url, influencer: influencer, data: [:])
    }

    func data(codable: Codable) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(codable)
    }

    func deviceRequest(env: Environment) -> DeviceRequest {
        let config = self.config(env: env)
        return DeviceRequest(tappToken: config.tappToken,
                             bundleID: bundleID,
                             mmp: config.affiliate.rawValue,
                             deviceID: config.deviceID)
    }

    func deviceResponse(active: Bool) -> DeviceResponse {
        return DeviceResponse(error: false,
                              device: Device(id: "id1", active: active),
                              message: nil)
    }

    func fetchDeviceRequest(env: Environment) -> URLRequest {
        let endpoint = TappEndpoint.device(deviceRequest(env: env))
        return endpoint.request!
    }

    func fetchDeviceCalled(env: Environment) -> Bool {
        let request = fetchDeviceRequest(env: env)
        return dependenciesHelper.networkClient.executeAuthenticatedRequests[request.url!.absoluteString] != nil
    }

    func fingerprintResponse(error: Bool?, message: String?, active: Bool) -> FingerprintResponse {
        return FingerprintResponse(deeplink: url,
                                   tappURL: url,
                                   attributedTappURL: url,
                                   influencer: "influencer",
                                   data: nil,
                                   deviceID: FingerprintResponse.DeviceID(id: "id1", active: active),
                                   error: error,
                                   message: message)
    }

    var message: WKScriptMessage {
        return TestScriptMessage()
    }
}

final class TestScriptMessage: WKScriptMessage {
    let overrideBody: String
    let overrideName: String

    init(overrideBody: String = "test", overrideName: String = "test") {
        self.overrideBody = overrideBody
        self.overrideName = overrideName
    }

    override var body: Any { overrideBody }
    override var name: String { overrideName }
}
