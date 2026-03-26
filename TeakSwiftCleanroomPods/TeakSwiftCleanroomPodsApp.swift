//
//  TeakSwiftCleanroomPodsApp.swift
//  TeakSwiftCleanroomPods
//
//  Created by Alexander Scarborough on 3/3/25.
//

import SwiftUI
import Teak

@main
struct TeakSwiftCleanroomPodsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Teak.initSwiftUI(forApplicationId: "1895209031564529690", andApiKey: "cbc7139c5ecf5379136f6c3f19366e3c")

    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
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
        return true
    }
}
