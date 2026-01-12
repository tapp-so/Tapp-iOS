import Foundation
import TappNetworking

final class NetworkClientMock: NetworkClientProtocol {

    var executeError: Error?
    var executeRequests: [String: URLRequest] = [:]
    var executeResponseData: [String: Data] = [:]
    func execute(request: URLRequest, completion: NetworkServiceCompletion?) -> URLSessionDataTaskProtocol? {
        let urlString = request.url!.absoluteString
        executeRequests[urlString] = request
        if let executeError {
            completion?(.failure(executeError))
            return nil
        }
        if let data = executeResponseData[urlString] {
            completion?(.success(data))
            return nil
        }
        return nil
    }

    var executeAuthenticatedError: Error?
    var executeAuthenticatedRequests: [String: URLRequest] = [:]
    var executeAuthenticatedResponseData: [String: Data] = [:]
    func executeAuthenticated(request: URLRequest, completion: NetworkServiceCompletion?) -> URLSessionDataTaskProtocol? {
        let urlString = request.url!.absoluteString
        executeAuthenticatedRequests[urlString] = request
        if let executeAuthenticatedError {
            completion?(.failure(executeAuthenticatedError))
            return nil
        }
        if let data = executeAuthenticatedResponseData[urlString] {
            completion?(.success(data))
            return nil
        }
        return nil
    }
}
