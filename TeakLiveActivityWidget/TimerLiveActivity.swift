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
            TimerLockScreenView(state: context.state)
        } dynamicIsland: { context in
            // Dynamic Island is required by the API even on devices without
            // Dynamic Island hardware. Provides fallback presentations.
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Timer", systemImage: "timer")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.caption)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.status)
                        .font(.caption2)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .monospacedDigit()
                    .font(.caption)
                    .frame(width: 44)
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
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Timer", systemImage: "timer")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(state.status)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            Text(timerInterval: Date.now...state.endDate, countsDown: true)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding()
        .background(.red.gradient)
    }
}
