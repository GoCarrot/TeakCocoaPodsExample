import ActivityKit
import Foundation

/// Defines the data model for a "Timer" Live Activity.
///
/// This type must be compiled by both the main app (which starts/updates/ends
/// activities) and the widget extension (which renders the Lock Screen UI).
/// That's why it lives in the Shared/ directory with target membership in both.
struct TimerActivityAttributes: ActivityAttributes {
    /// ContentState holds the data that changes over the activity's lifetime.
    /// Each update (local or via push) provides a new ContentState instance.
    ///
    /// For push-based updates, the server sends this as the "content-state"
    /// JSON field in the APNs payload. The JSON keys must exactly match these
    /// property names (or their CodingKeys if customized).
    struct ContentState: Codable, Hashable {
        /// The time when the timer expires. The widget uses this with
        /// Text(timerInterval:) to render an auto-updating countdown.
        var endDate: Date

        /// A human-readable status string displayed alongside the timer.
        var status: String
    }

    // No static (per-activity) properties for this demo.
    // In a real app, you might have something like:
    //   var activityName: String
    //   var userId: String
    // These are set once at activity creation and never change.
}
