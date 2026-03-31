import ActivityKit
import Foundation

/// Defines the data model for a "Countdown" Live Activity.
///
/// Structurally similar to TimerActivityAttributes but semantically distinct.
/// Having two types demonstrates that:
///   1. Each ActivityAttributes type gets its own push-to-start token
///   2. Each activity instance gets its own push update token
///   3. JSON introspection produces different schemas per type
///   4. The widget extension needs a separate ActivityConfiguration per type
struct CountdownActivityAttributes: ActivityAttributes {
    /// ContentState for countdown activities. Note the field is "phase"
    /// instead of "status" — different types have different schemas, which
    /// the server must know to construct valid push payloads.
    struct ContentState: Codable, Hashable {
        /// The time when the countdown completes.
        var endDate: Date

        /// The current phase of the countdown.
        var phase: String
    }

    /// Static attributes — set at creation, immutable for the activity's lifetime.
    var name: String
}
