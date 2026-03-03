import ActivityKit
import Foundation

struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timerEnd: Date
    }
    var duration: TimeInterval
}
 
