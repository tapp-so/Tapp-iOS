//
//  TappEndpoint.swift
//

import Foundation
import TappNetworking

public enum APIPath: String {
    case id
    case influencer
    case add
    case deeplink
    case secrets
    case event
    case linkData
    case fingerprint
    case device

    public var prefixInfluencer: String {
        return rawValue.prefixInfluencer
    }

    public var prefixAdd: String {
        return rawValue.prefixAdd
    }
}

extension String {

    public var prefixInfluencer: String {
        return prefix(APIPath.influencer.rawValue)
    }

    public var prefixAdd: String {
        return prefix(APIPath.add.rawValue)
    }

    public func prefix(_ value: String) -> String {
        return "\(value)/" + self
    }
}

enum TappEndpoint: Endpoint {
    case generateURL(CreateAffiliateURLRequest)
    case deeplink(ImpressionRequest)
    case secrets(SecretsRequest)
    case tappEvent(TappEventRequest)
    case linkData(TappLinkDataRequest)
    case fingerpint(Fingerprint)
    case device(DeviceRequest)

    var httpMethod: HTTPMethod {
        switch self {
        case .generateURL, .deeplink, .secrets, .tappEvent, .linkData, .fingerpint, .device:
            return .post
        }
    }

    var path: String {
        switch  self {
        case .generateURL:
            return APIPath.add.prefixInfluencer
        case .deeplink:
            return APIPath.deeplink.rawValue
        case .secrets:
            return APIPath.secrets.rawValue
        case .tappEvent:
            return APIPath.event.rawValue
        case .linkData:
            return APIPath.linkData.rawValue
        case .fingerpint:
            return APIPath.fingerprint.rawValue
        case .device:
            return APIPath.device.rawValue
        }
    }

    var request: URLRequest? {
        switch self {
        case .generateURL(let requestData):
            return request(encodable: requestData)
        case .deeplink(let requestData):
            return request(encodable: requestData)
        case .secrets(let requestData):
            return request(encodable: requestData)
        case .tappEvent(let requestData):
            return request(encodable: requestData)
        case .linkData(let requestData):
            return request(encodable: requestData)
        case .fingerpint(let requestData):
            return request(encodable: requestData)
        case .device(let requestData):
            return request(encodable: requestData)
        }
    }
}
