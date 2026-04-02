//
//  ContentView.swift
//  TeakSwiftCleanroomPods
//
//  Created by Alexander Scarborough on 3/3/25.
//

import SwiftUI
import ActivityKit

struct ContentView: View {
    // MARK: - Timer Activity State

    /// Reference to the running Timer activity, nil when inactive.
    @State private var timerActivity: Activity<TimerActivityAttributes>? = nil
    /// Async task observing the activity's push token updates.
    @State private var timerPushTokenTask: Task<Void, Never>? = nil
    /// Async task observing push-to-start token updates for the Timer type.
    @State private var timerPTSTokenTask: Task<Void, Never>? = nil

    // MARK: - Countdown Activity State

    @State private var countdownActivity: Activity<CountdownActivityAttributes>? = nil
    @State private var countdownPushTokenTask: Task<Void, Never>? = nil
    @State private var countdownPTSTokenTask: Task<Void, Never>? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Live Activity Controls")
                    .font(.title2.bold())

                // MARK: - Timer Activity Section (Red)

                GroupBox {
                    VStack(spacing: 12) {
                        Label("Timer Activity", systemImage: "timer")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            Button("Start") { startTimerActivity() }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .disabled(timerActivity != nil)

                            Button("Update") { updateTimerActivity() }
                                .buttonStyle(.bordered)
                                .disabled(timerActivity == nil)

                            Button("Dismiss") { dismissTimerActivity() }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .disabled(timerActivity == nil)
                        }
                    }
                }

                // MARK: - Countdown Activity Section (Blue)

                GroupBox {
                    VStack(spacing: 12) {
                        Label("Countdown Activity", systemImage: "hourglass")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            Button("Start") { startCountdownActivity() }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled(countdownActivity != nil)

                            Button("Update") { updateCountdownActivity() }
                                .buttonStyle(.bordered)
                                .disabled(countdownActivity == nil)

                            Button("Dismiss") { dismissCountdownActivity() }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                                .disabled(countdownActivity == nil)
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            startPushToStartTokenObservation()
        }
    }

    // ========================================================================
    // MARK: - Push-to-Start Token Observation
    // ========================================================================

    /// Starts push-to-start token observation for all activity types.
    /// Called once on view appear. Push-to-start tokens are per-type (not
    /// per-instance), persist across app launches, and should be observed
    /// as early as possible so the system knows to generate them.
    /// In production, this would go in application(_:didFinishLaunchingWithOptions:).
    private func startPushToStartTokenObservation() {
        guard timerPTSTokenTask == nil else { return }

        timerPTSTokenTask = Task {
            for await tokenData in Activity<TimerActivityAttributes>.pushToStartTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[Timer] Push-to-start token: \(token)")
                print("[Timer]   type: TimerActivityAttributes (covers all future instances)")
            }
        }

        countdownPTSTokenTask = Task {
            for await tokenData in Activity<CountdownActivityAttributes>.pushToStartTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[Countdown] Push-to-start token: \(token)")
                print("[Countdown]   type: CountdownActivityAttributes")
            }
        }
    }

    // ========================================================================
    // MARK: - Timer Activity Lifecycle
    // ========================================================================

    private func startTimerActivity() {
        let endDate = Date.now.addingTimeInterval(5 * 60) // 5 minutes from now

        // 1. Construct the initial ContentState with a timer end date and status.
        let initialState = TimerActivityAttributes.ContentState(
            endDate: endDate,
            status: "In Progress"
        )

        // 2. Request the activity. pushType: .token is required to receive push
        //    tokens — without it, only local updates work.
        let attributes = TimerActivityAttributes(name: "My Timer")
        let content = ActivityContent(state: initialState, staleDate: endDate)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            timerActivity = activity
            print("[Timer] Started activity: \(activity.id)")

            // 3. Observe per-activity push token. Each activity instance gets its
            //    own unique token. The token may change during the activity's
            //    lifetime (the server must update its records when this happens).
            //    The token is device-bound and instance-specific — it becomes
            //    invalid when the activity ends. The async sequence completes
            //    when the activity ends or the task is cancelled.
            //    The server uses this token with APNs topic:
            //    "{bundle_id}.push-type.liveactivity"
            timerPushTokenTask = Task {
                for await tokenData in activity.pushTokenUpdates {
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()
                    print("[Timer] Activity push token: \(token)")
                    print("[Timer]   instance: \(activity.id)")
                }
                print("[Timer] Push token observation ended (activity ended or task cancelled)")
            }

            // 4. Introspect the ContentState schema — discover the JSON shape
            //    the server needs for push-based updates.
            introspectContentState(initialState, typeName: "TimerActivityAttributes")

        } catch {
            print("[Timer] Failed to start activity: \(error)")
        }
    }

    private func updateTimerActivity() {
        guard let activity = timerActivity else { return }

        // Construct a new ContentState with an updated status. The endDate stays
        // the same — the timer keeps counting down. staleDate tells the system
        // when this content should be considered outdated.
        let updatedState = TimerActivityAttributes.ContentState(
            endDate: activity.content.state.endDate,
            status: "Almost Done!"
        )
        let content = ActivityContent(
            state: updatedState,
            staleDate: activity.content.state.endDate
        )

        Task {
            await activity.update(content)
            print("[Timer] Updated status to: \(updatedState.status)")
        }
    }

    private func dismissTimerActivity() {
        guard let activity = timerActivity else { return }

        // End the activity with a final ContentState. dismissalPolicy controls
        // how long the activity lingers on the Lock Screen after ending:
        //   .immediate    — removed right away
        //   .default      — lingers up to 4 hours showing final state
        //   .after(Date)  — removed at the specified time
        let finalState = TimerActivityAttributes.ContentState(
            endDate: activity.content.state.endDate,
            status: "Complete"
        )
        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
            print("[Timer] Dismissed activity")
        }

        // Cancel activity push token observation — the token is no longer
        // valid once the activity ends. Push-to-start observation continues
        // (it's per-type, not per-instance).
        timerPushTokenTask?.cancel()
        timerPushTokenTask = nil
        timerActivity = nil
    }

    // ========================================================================
    // MARK: - Countdown Activity Lifecycle
    // ========================================================================

    private func startCountdownActivity() {
        let endDate = Date.now.addingTimeInterval(5 * 60)

        let initialState = CountdownActivityAttributes.ContentState(
            endDate: endDate,
            phase: "Active"
        )

        let attributes = CountdownActivityAttributes(name: "My Countdown")
        let content = ActivityContent(state: initialState, staleDate: endDate)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            countdownActivity = activity
            print("[Countdown] Started activity: \(activity.id)")

            // Per-activity push token — same lifecycle as Timer (see comments
            // in startTimerActivity). This is a separate token from any Timer
            // activity tokens.
            countdownPushTokenTask = Task {
                for await tokenData in activity.pushTokenUpdates {
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()
                    print("[Countdown] Activity push token: \(token)")
                    print("[Countdown]   instance: \(activity.id)")
                }
                print("[Countdown] Push token observation ended")
            }

            introspectContentState(initialState, typeName: "CountdownActivityAttributes")

        } catch {
            print("[Countdown] Failed to start activity: \(error)")
        }
    }

    private func updateCountdownActivity() {
        guard let activity = countdownActivity else { return }

        let updatedState = CountdownActivityAttributes.ContentState(
            endDate: activity.content.state.endDate,
            phase: "Final Phase!"
        )
        let content = ActivityContent(
            state: updatedState,
            staleDate: activity.content.state.endDate
        )

        Task {
            await activity.update(content)
            print("[Countdown] Updated phase to: \(updatedState.phase)")
        }
    }

    private func dismissCountdownActivity() {
        guard let activity = countdownActivity else { return }

        let finalState = CountdownActivityAttributes.ContentState(
            endDate: activity.content.state.endDate,
            phase: "Complete"
        )
        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
            print("[Countdown] Dismissed activity")
        }

        countdownPushTokenTask?.cancel()
        countdownPushTokenTask = nil
        countdownActivity = nil
    }

    // ========================================================================
    // MARK: - ContentState Schema Introspection
    // ========================================================================

    /// Introspects a ContentState instance to discover the JSON schema the
    /// server needs for push-based updates.
    ///
    /// Uses Mirror reflection to enumerate property names and Swift types, then
    /// JSON-encodes the instance to show the exact payload shape APNs expects
    /// in the "content-state" field.
    ///
    /// Limitations:
    ///   - Mirror gives runtime types, not declared types (Optional<String>
    ///     shows as String when non-nil)
    ///   - No way to get the schema from just the type without an instance
    ///   - Custom CodingKeys cause Mirror names to differ from JSON keys
    ///     (JSON encoding is the source of truth)
    private func introspectContentState<T: Codable>(_ state: T, typeName: String) {
        print("[\(typeName)] --- ContentState Schema Introspection ---")

        // Mirror reflection: property names and Swift types
        let mirror = Mirror(reflecting: state)
        print("[\(typeName)] Properties (via Mirror):")
        for child in mirror.children {
            let label = child.label ?? "(unlabeled)"
            let valueType = type(of: child.value)
            print("[\(typeName)]   \(label): \(valueType) = \(child.value)")
        }

        // JSON encoding: the exact payload shape the server needs
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let jsonData = try? encoder.encode(state),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[\(typeName)] JSON shape (APNs content-state payload):")
            print(jsonString)

            if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                print("[\(typeName)] Fields:")
                for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                    let jsonType: String
                    switch value {
                    case is String: jsonType = "string"
                    case is NSNumber: jsonType = "number"
                    case is [Any]: jsonType = "array"
                    case is [String: Any]: jsonType = "object"
                    default: jsonType = "unknown"
                    }
                    print("[\(typeName)]   \(key): \(jsonType)")
                }
            }
        }

        print("[\(typeName)] --- End Schema Introspection ---")
    }
}

#Preview {
    ContentView()
}
