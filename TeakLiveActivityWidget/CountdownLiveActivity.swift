import ActivityKit
import WidgetKit
import SwiftUI

/// Widget configuration for CountdownActivityAttributes.
/// Same structural pattern as TimerLiveActivity with blue visuals.
struct CountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CountdownActivityAttributes.self) { context in
            CountdownLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Countdown", systemImage: "hourglass")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.caption)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.phase)
                        .font(.caption2)
                }
            } compactLeading: {
                Image(systemName: "hourglass")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .monospacedDigit()
                    .font(.caption)
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "hourglass")
                    .foregroundStyle(.blue)
            }
        }
    }
}

/// Lock Screen view for countdown activities. Blue background visually
/// distinguishes this from timer activities (red).
struct CountdownLockScreenView: View {
    let state: CountdownActivityAttributes.ContentState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Countdown", systemImage: "hourglass")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(state.phase)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            Text(timerInterval: Date.now...state.endDate, countsDown: true)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding()
        .background(.blue.gradient)
    }
}
