import Foundation

@objc
public final class TappEvent: NSObject {
    let eventAction: EventAction
    let metadata: [String: Encodable]?

    public init(eventAction: EventAction, metadata: [String: Encodable]? = nil) {
        self.eventAction = eventAction
        self.metadata = TappEvent.filtered(metadata: metadata)
        super.init()
    }

    @objc
    public init(eventActionName: String, metadata: [String: Any]?) {
        let mapper = EventActionMapper(eventActionName: eventActionName)
        let eventAction = mapper.eventAction
        self.eventAction = eventAction
        self.metadata = TappEvent.filtered(metadata: metadata)

        super.init()
    }
}

private extension TappEvent {
    static func filtered(metadata: [String: Any]?) -> [String: Encodable]? {
        if let metadata {
            var mappedDict: [String: Encodable] = [:]
            for (key, value) in metadata {
                if let v = value as? String {
                    mappedDict[key] = v
                } else if let v = value as? Int {
                    mappedDict[key] = v
                } else if let v = value as? Double {
                    mappedDict[key] = v
                } else if let v = value as? Bool {
                    mappedDict[key] = v
                }
            }

            return mappedDict
        }
        return nil
    }
}
