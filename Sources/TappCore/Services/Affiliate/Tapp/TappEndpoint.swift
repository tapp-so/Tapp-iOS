//
//  TappEndpoint.swift
//

import Foundation
import TappNetworking

enum TappEndpoint: Endpoint {
    case generateURL(CreateAffiliateURLRequest)
    case deeplink(ImpressionRequest)
    case secrets(SecretsRequest)
    case tappEvent(TappEventRequest)
    case linkData(TappLinkDataRequest)

    var httpMethod: HTTPMethod {
        switch self {
        case .generateURL, .deeplink, .secrets, .tappEvent, .linkData:
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
        }
    }
}
