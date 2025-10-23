import Foundation

@objc
public final class TappEvent: NSObject {
    let eventAction: EventAction

    public init(eventAction: EventAction) {
        self.eventAction = eventAction
        super.init()
    }

    @objc
    public init(eventActionName: String) {
        let mapper = EventActionMapper(eventActionName: eventActionName)
        let eventAction = mapper.eventAction
        self.eventAction = eventAction
        super.init()
    }
}
