import Testing
import XCTest
import TappNetworking
@testable import Tapp

final class TappTests: XCTestCase {
    var dependenciesHelper: DependenciesHelper!
    var sut: Tapp!
    var tappDelegate: TappDelegateMock!
    override func setUp() {
        dependenciesHelper = .init()
        tappDelegate = .init()
        sut = Tapp(dependencies: dependenciesHelper.dependencies)
        super.setUp()
    }

    override func tearDown() {
        dependenciesHelper = nil
        super.tearDown()
    }

    func testStartWithoutStoredConfig() {
        XCTAssertNil(dependenciesHelper.keychainHelper.config)

        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()

        sut.start(config: config, delegate: tappDelegate)

        XCTAssertEqual(dependenciesHelper.keychainHelper.setBundleID, "bundleID123")
        XCTAssertEqual(dependenciesHelper.keychainHelper.setEnvironment, .sandbox)
        XCTAssertNotNil(dependenciesHelper.keychainHelper.config)
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 1)

        XCTAssertTrue(dependenciesHelper.tappAffiliateService.secretsCalled)
    }

    func testStartWithStoredConfig() {
        dependenciesHelper.keychainHelper.configObject = config

        sut.start(config: config, delegate: tappDelegate)

        XCTAssertEqual(dependenciesHelper.keychainHelper.setBundleID, "bundleID123")
        XCTAssertEqual(dependenciesHelper.keychainHelper.setEnvironment, .sandbox)
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 0)
    }

    func testInitializeEngineWithMissingConfiguration() {
        sut.initializeEngine { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let tappError = error as? TappError else {
                    XCTFail()
                    return
                }
                switch tappError {
                case .missingConfiguration:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testInitializeEngine() {
        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsResponse = SecretsResponse(secret: "secret", brandedURL: URL(string: "https://tapp.so")!)

        let expectation = expectation(description: "testInitializeEngine")
        sut.initializeEngine { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(dependenciesHelper.tappAffiliateService.secretsCalled)
    }

    func testURL() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsResponse = SecretsResponse(secret: "secret", brandedURL: url)
        dependenciesHelper.tappAffiliateService.urlResponse = GeneratedURLResponse(url: url)
        let expectation = expectation(description: "testInitializeEngine")
        let configuration = AffiliateURLConfiguration(influencer: "influencer", adgroup: "adgroup", creative: "creative", data: [:])
        sut.url(config: configuration) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.url, url)
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(dependenciesHelper.tappAffiliateService.initializeCalled)
    }

    func testFetchLinkDataWhenShouldProcessFalse() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.tappAffiliateService.shouldProcessURL = false

        sut.internalFetchLinkData(for: url) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .unprocessableEntity:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testHandleEvent() {
        var event = TappEvent(eventAction: .custom(.empty))
        sut.handleTappEvent(event: event)
        XCTAssertEqual(dependenciesHelper.tappAffiliateService.sendTappEventCount, 0)

        event = TappEvent(eventAction: .custom("some_value"))
        sut.handleTappEvent(event: event)
        XCTAssertEqual(dependenciesHelper.tappAffiliateService.sendTappEventCount, 1)

        event = TappEvent(eventAction: .addToCart)
        sut.handleTappEvent(event: event)
        XCTAssertEqual(dependenciesHelper.tappAffiliateService.sendTappEventCount, 2)
    }

    func testFetchLinkDataWhenShouldProcessTrue() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsResponse = SecretsResponse(secret: "secret", brandedURL: url)
        dependenciesHelper.tappAffiliateService.shouldProcessURL = true

        dependenciesHelper.tappAffiliateService.fetchLinkDataDTO = TappDeferredLinkDataDTO(tappURL: url,
                                                                                           attributedTappURL: url,
                                                                                           influencer: "influencer",
                                                                                           data: [:])

        let expectation = expectation(description: "testFetchLinkDataWhenShouldProcessTrue")

        sut.internalFetchLinkData(for: url) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.tappURL, url)
                XCTAssertEqual(response.attributedTappURL, url)
                XCTAssertEqual(response.influencer, "influencer")
                XCTAssertEqual(response.data, [:])
                
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertNil(dependenciesHelper.keychainHelper.config?.originURL)
    }

    func testInitializeEngineWithSecretsError() {
        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsError = TappTestsError.secrets

        let expectation = expectation(description: "testInitializeEngineWithSecretsError")

        sut.initializeEngine { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappError else {
                    XCTFail()
                    return
                }
                switch err {
                case .affiliateServiceError(affiliate: let affiliate, underlyingError: let underlyingError):
                    XCTAssertEqual(affiliate, .tapp)
                    guard let tappError = underlyingError as? TappError else {
                        XCTFail()
                        return
                    }
                    switch tappError {
                    case .affiliateServiceError(affiliate: _, underlyingError: let tErr):
                        guard let tErr = tErr as? TappTestsError else {
                            XCTFail()
                            return
                        }
                        switch tErr {
                        case .secrets:
                            break
                        default:
                            XCTFail()
                        }
                    default:
                        XCTFail()
                    }
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }
        sut.initializeEngine(completion: nil)

        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(dependenciesHelper.tappAffiliateService.secretsCalled)
        XCTAssertEqual(dependenciesHelper.tappAffiliateService.secretsCalledCount, 1)
    }

    func testSecretsSuccess() {
        let configuration = config
        dependenciesHelper.keychainHelper.configObject = configuration
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsResponse = SecretsResponse(secret: "secret1", brandedURL: URL(string: "https://tapp.so")!)

        _ = sut.secrets(config: configuration) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let url):
                XCTAssertEqual(self.dependenciesHelper.keychainHelper.saveCalledCount, 1)
                XCTAssertEqual(self.dependenciesHelper.keychainHelper.config?.appToken, "secret1")
                XCTAssertEqual(url?.absoluteString, "https://tapp.so")
            case .failure:
                XCTFail()
            }
        }
    }

    func testInitializeServiceWithMissingService() {
        let configuration = TappConfiguration(authToken: "authToken123",
                                              env: .sandbox,
                                              tappToken: "tappToken123",
                                              affiliate: .adjust,
                                              bundleID: "bundleID123")
        dependenciesHelper.keychainHelper.configObject = configuration
        sut.initializeAffiliateService(brandedURL: URL(string: "https://tapp.so")) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappError else {
                    XCTFail()
                    return
                }
                switch err {
                case .missingParameters(details: _):
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testInitializeServiceWithAlreadyInitialized() {
        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.isInitialized = true

        let expectation = expectation(description: "testInitializeServiceWithAlreadyInitialized")

        sut.initializeAffiliateService(brandedURL: URL(string: "https://tapp.so")) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(dependenciesHelper.tappAffiliateService.initializeCalled)
    }

    func testInitializeServiceSuccess() {
        dependenciesHelper.keychainHelper.configObject = config

        let expectation = expectation(description: "testInitializeServiceSuccess")

        sut.initializeAffiliateService(brandedURL: URL(string: "https://tapp.so")) { result in
            switch result {
            case .success:
                break
            case .failure:
                break
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(dependenciesHelper.tappAffiliateService.initializeCalled)
        XCTAssertTrue(dependenciesHelper.keychainHelper.config!.hasProcessedReferralEngine)
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 1)
    }

    func testHasProcessedReferralEngine() {
        XCTAssertFalse(sut.hasProcessedReferralEngine())

        dependenciesHelper.keychainHelper.configObject = config
        XCTAssertFalse(sut.hasProcessedReferralEngine())

        dependenciesHelper.keychainHelper.configObject?.set(hasProcessedReferralEngine: true)
        XCTAssertTrue(sut.hasProcessedReferralEngine())
    }

    func testShouldProcessURL() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.tappAffiliateService.shouldProcessURL = false
        XCTAssertFalse(sut.shouldProcess(url: url))

        dependenciesHelper.tappAffiliateService.shouldProcessURL = true
        XCTAssertTrue(sut.shouldProcess(url: url))
    }

    func testFetchLinkDataWithShouldProcessFalse() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.tappAffiliateService.shouldProcessURL = false

        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsResponse = SecretsResponse(secret: "secret", brandedURL: url)

        let expectation = expectation(description: "testFetchLinkDataWithShouldProcessFalse")
        sut.internalFetchLinkData(for: url) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let err = error as? TappServiceError else {
                    XCTFail()
                    return
                }
                switch err {
                case .unprocessableEntity:
                    break
                default:
                    XCTFail()
                }
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(dependenciesHelper.tappAffiliateService.secretsCalled)
    }

    func testFetchLinkDataWithShouldProcessTrue() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.tappAffiliateService.shouldProcessURL = true

        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsResponse = SecretsResponse(secret: "secret", brandedURL: url)

        let dto = TappDeferredLinkDataDTO(tappURL: url, attributedTappURL: url, influencer: "influencer", data: nil)
        dependenciesHelper.tappAffiliateService.fetchLinkDataDTO = dto

        let expectation = expectation(description: "testFetchLinkDataWithShouldProcessTrue")
        sut.internalFetchLinkData(for: url) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(dependenciesHelper.tappAffiliateService.secretsCalled)
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 2)
        XCTAssertTrue(dependenciesHelper.tappAffiliateService.fetchLinkDataCalled)
    }

    func testFetchOriginLinkDataMissingData() {
        sut.fetchOriginLinkData { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                guard let error = error as? TappServiceError else {
                    XCTFail()
                    return
                }
                switch error {
                case .notFound:
                    break
                default:
                    XCTFail()
                }
            }
        }
    }

    func testFetchOriginLinkDataExistingData() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.keychainHelper.configObject?.set(originURL: url)
        dependenciesHelper.keychainHelper.configObject?.set(originAttributedTappURL: url)
        dependenciesHelper.keychainHelper.configObject?.set(originInfluencer: "influencer")

        let data: [String: String?] = ["key1": "value1", "key2": nil]
        dependenciesHelper.keychainHelper.configObject?.set(originData: data)

        sut.fetchOriginLinkData { result in
            switch result {
            case .success(let dto):
                XCTAssertEqual(dto.data, ["key1": "value1"])
            case .failure:
                XCTFail()
            }
        }
    }

    func testDidReceiveDeferredLinkWithNilDelegate() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.tappAffiliateService.shouldProcessURL = true
        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsResponse = SecretsResponse(secret: "secret", brandedURL: url)

        sut.didReceiveDeferredLink(url)
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(dependenciesHelper.tappAffiliateService.handleImpressionCalled)
        XCTAssertFalse(dependenciesHelper.tappAffiliateService.fetchLinkDataCalled)
    }

    func testDidReceiveDeferredLinkWithDelegate() {
        let url = URL(string: "https://tapp.so")!
        dependenciesHelper.tappAffiliateService.shouldProcessURL = true
        dependenciesHelper.keychainHelper.configObject = config
        dependenciesHelper.tappAffiliateService.secretsDataTask = .init()
        dependenciesHelper.tappAffiliateService.secretsResponse = SecretsResponse(secret: "secret", brandedURL: url)
        sut.delegate = tappDelegate
        let dto = TappDeferredLinkDataDTO(tappURL: url, attributedTappURL: url, influencer: "influencer", data: nil)
        dependenciesHelper.tappAffiliateService.fetchLinkDataDTO = dto

        sut.didReceiveDeferredLink(url)
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(dependenciesHelper.tappAffiliateService.handleImpressionCalled)
        XCTAssertTrue(dependenciesHelper.tappAffiliateService.fetchLinkDataCalled)
        XCTAssertEqual(dependenciesHelper.keychainHelper.saveCalledCount, 3)
        XCTAssertTrue(tappDelegate.didOpenApplicationCalled)
        XCTAssertNotNil(tappDelegate.didOpenApplicationData)
        XCTAssertEqual(tappDelegate.didOpenApplicationData?.tappURL, dto.tappURL)
        XCTAssertEqual(tappDelegate.didOpenApplicationData?.attributedTappURL, dto.attributedTappURL)
        XCTAssertEqual(tappDelegate.didOpenApplicationData?.influencer, dto.influencer)
        XCTAssertEqual(tappDelegate.didOpenApplicationData?.data, dto.data)
    }

    func testDidReceiveFingerprintResponse() {
        let response = FingerprintResponse.response(error: false, hasMessage: true)
        sut.delegate = tappDelegate
        sut.didReceive(fingerprintResponse: response)
        XCTAssertTrue(tappDelegate.didOpenApplicationCalled)
        XCTAssertNotNil(tappDelegate.didOpenApplicationData)
        XCTAssertEqual(tappDelegate.didOpenApplicationData?.tappURL, response.tappURL)
        XCTAssertEqual(tappDelegate.didOpenApplicationData?.attributedTappURL, response.attributedTappURL)
        XCTAssertEqual(tappDelegate.didOpenApplicationData?.influencer, response.influencer)
        XCTAssertEqual(tappDelegate.didOpenApplicationData?.data, response.data)
        XCTAssertNotNil(dependenciesHelper.tappAffiliateService.handleImpressionCalled)
    }
}

private extension TappTests {
    var config: TappConfiguration {
        return TappConfiguration(authToken: "authToken123",
                                 env: .sandbox,
                                 tappToken: "tappToken123",
                                 affiliate: .tapp,
                                 bundleID: "bundleID123")
    }
}

enum TappTestsError: Error {
    case undefined
    case secrets
}
