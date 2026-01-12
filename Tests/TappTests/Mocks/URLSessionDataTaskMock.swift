import Foundation
import TappNetworking

final class URLSessionDataTaskMock: URLSessionDataTaskProtocol {
    let identifier: Int

    init(identifier: Int = 0) {
        self.identifier = identifier
    }

    func resume() {

    }
    
    func cancel() {

    }
}
