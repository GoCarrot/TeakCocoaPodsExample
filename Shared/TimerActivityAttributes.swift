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
        /// A human-readable status string displayed alongside the timer.
        var status: String
    }

    /// Static attributes are set at creation time and cannot change for the
    /// lifetime of the activity. Both local starts and push-to-start payloads
    /// provide these values. The widget extension can reference them alongside
    /// the dynamic ContentState.
    var name: String
}
