import ActivityKit
import WidgetKit
import SwiftUI

/// Widget configuration for TimerActivityAttributes.
///
/// ActivityConfiguration maps an ActivityAttributes type to its visual
/// presentations. The two closures define the Lock Screen view and the
/// Dynamic Island view respectively.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen / banner presentation
            TimerLockScreenView(name: context.attributes.name, state: context.state)
        } dynamicIsland: { context in
            // Dynamic Island is required by the API even on devices without
            // Dynamic Island hardware. Provides fallback presentations.
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Timer", systemImage: "timer")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text(context.state.status)
                    .font(.caption)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.red)
            }
        }
    }
}

/// Lock Screen view for timer activities. Red background visually
/// distinguishes this from countdown activities (blue).
struct TimerLockScreenView: View {
    let name: String
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label(name, systemImage: "timer")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(state.status)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding()
        .background(.red.gradient)
    }
}
