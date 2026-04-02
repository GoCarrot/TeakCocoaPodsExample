//
//  TeakSwiftCleanroomPodsApp.swift
//  TeakSwiftCleanroomPods
//
//  Created by Alexander Scarborough on 3/3/25.
//

import SwiftUI
import ActivityKit
import WidgetKit
import Teak

@main
struct TeakSwiftCleanroomPodsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Teak.initSwiftUI(forApplicationId: "1895209031564529690", andApiKey: "cbc7139c5ecf5379136f6c3f19366e3c")
    }
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("[App] onOpenURL: \(url)")
                }
                .onContinueUserActivity(NSUserActivityTypeLiveActivity) { activity in
                    print("[App] onContinueUserActivity (Live Activity tap)")
                    print("[App]   activityType: \(activity.activityType)")
                    if let userInfo = activity.userInfo {
                        print("[App]   userInfo: \(userInfo)")
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("[App] scenePhase: \(oldPhase) -> \(newPhase)")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("[AppDelegate] didFinishLaunchingWithOptions")
        if let launchOptions {
            print("[AppDelegate]   launchOptions keys: \(launchOptions.keys.map { $0.rawValue })")
            for (key, value) in launchOptions {
                print("[AppDelegate]   \(key.rawValue): \(value)")
            }
        } else {
            print("[AppDelegate]   launchOptions: nil")
        }
        print("[AppDelegate]   applicationState: \(application.applicationState.rawValue)")

        NotificationCenter.default.addObserver(forName: Notification.Name(TeakOnReward), object: nil, queue: nil, using:{notification in
            let rewardStatus = notification.userInfo!["status"] as! String
            switch rewardStatus {
            case "grant_reward":
                print("Reward Granted!")
            case "already_clicked":
                print("Already claimed!")
            default:
                print("Unknown status")
            }
        })
        Teak.registerDeepLinkRoute("/slots/:slot_name", name: "Go to Slot", description: "Take the player directly to a slot", block: {params in
            print("Taking the player to \(String(describing: params["slot_name"]))")
        })

        Teak.requestNotificationPermissions({accepted, error in
            print("User accepted notifications: \(accepted)");
        })
        Teak.login("native-swift-sample-pods", with: TeakUserConfiguration())
        Teak.setStringProperty("favorite_slot", value: "demo")
        Teak.setNumberProperty("bankroll", value: 12345)

        observePushToStartTokens()
        observeActivityUpdates()

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("[AppDelegate] configurationForConnecting")
        if let userActivity = options.userActivities.first {
            print("[AppDelegate]   userActivity.activityType: \(userActivity.activityType)")
            if let userInfo = userActivity.userInfo {
                print("[AppDelegate]   userActivity.userInfo: \(userInfo)")
            }
        }
        if !options.urlContexts.isEmpty {
            print("[AppDelegate]   urlContexts: \(options.urlContexts.map { $0.url })")
        }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        return config
    }

    // MARK: - Live Activity Token Observation

    /// Observe push-to-start tokens for all activity types. These are per-type,
    /// per-device tokens that allow the server to create new activities remotely.
    /// Must run at launch so the system knows to generate tokens.
    private func observePushToStartTokens() {
        Task {
            for await tokenData in Activity<TimerActivityAttributes>.pushToStartTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[Timer] Push-to-start token: \(token)")
            }
        }

        Task {
            for await tokenData in Activity<CountdownActivityAttributes>.pushToStartTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[Countdown] Push-to-start token: \(token)")
            }
        }
    }

    /// Observe activityUpdates to discover activities created by push-to-start
    /// (or any other external source), and start watching their push tokens.
    /// Also checks for activities that already exist at launch.
    private func observeActivityUpdates() {
        // Pick up activities that already exist (created while app was killed)
        for activity in Activity<TimerActivityAttributes>.activities {
            print("[Timer] Found existing activity: \(activity.id)")
            observeActivityPushToken(activity, label: "Timer")
        }
        for activity in Activity<CountdownActivityAttributes>.activities {
            print("[Countdown] Found existing activity: \(activity.id)")
            observeActivityPushToken(activity, label: "Countdown")
        }

        // Watch for new activities created after launch
        Task {
            for await activity in Activity<TimerActivityAttributes>.activityUpdates {
                print("[Timer] New activity via activityUpdates: \(activity.id)")
                self.observeActivityPushToken(activity, label: "Timer")
            }
        }
        Task {
            for await activity in Activity<CountdownActivityAttributes>.activityUpdates {
                print("[Countdown] New activity via activityUpdates: \(activity.id)")
                self.observeActivityPushToken(activity, label: "Countdown")
            }
        }
    }

    private func observeActivityPushToken<T: ActivityAttributes>(_ activity: Activity<T>, label: String) {
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[\(label)] Activity push token: \(token)")
                print("[\(label)]   instance: \(activity.id)")
            }
            print("[\(label)] Push token observation ended for: \(activity.id)")
        }
    }
}
