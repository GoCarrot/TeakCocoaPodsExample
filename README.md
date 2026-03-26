# Teak SDK — SwiftUI + CocoaPods Example

A complete example of integrating the [Teak](https://teak.io) SDK into a SwiftUI iOS app using CocoaPods. This project demonstrates SDK initialization, push notifications (including rich push with notification extensions), deep linking, reward handling, and player properties.

This is the companion example project for the [Teak iOS Quickstart Guide](https://docs.teak.io/ios/latest/quickstart/index.html).

## What's Included

| Target | Purpose |
|--------|---------|
| **TeakCocoaPodsExample** | Main SwiftUI app with Teak SDK initialization, user login, deep links, and reward handling |
| **TeakNotificationService** | Notification Service Extension for processing push payloads |
| **TeakContentExtension** | Notification Content Extension for rich, interactive push notifications |

## Getting Started

### Prerequisites

- A Mac with Xcode installed
- [CocoaPods](https://cocoapods.org/)
- A [Teak](https://app.teak.io) account with your App ID and API Key

If you don't have a Teak account yet, [sign up](https://app.teak.io/signup) and create a game project by following the [Initial Setup](https://docs.teak.io/ios/latest/quickstart/new-game.html) guide. You'll also need to configure your [iOS Push Credentials](https://docs.teak.io/ios/latest/quickstart/apple-apns.html) in the Teak dashboard.

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/GoCarrot/TeakCocoaPodsExample.git
   cd TeakCocoaPodsExample
   ```

2. Install dependencies:
   ```bash
   pod install
   ```

3. Open the **workspace** (not the `.xcodeproj`):
   ```bash
   open TeakSwiftCleanroomPods.xcworkspace
   ```

4. Replace the placeholder credentials in `TeakSwiftCleanroomPodsApp.swift` with your own:
   ```swift
   Teak.initSwiftUI(forApplicationId: "<YOUR_APP_ID>", andApiKey: "<YOUR_API_KEY>")
   ```

5. Update the URL scheme in your target's Info tab. Teak requires a URL scheme of `teak<YOUR_APP_ID>` (e.g. `teak1234567890`) for deep link handling.

6. Build and run on a device or simulator.

## How It Works

### SDK Initialization (SwiftUI)

In a SwiftUI app, initialize Teak in your `App` struct's `init()` and use `@UIApplicationDelegateAdaptor` to bridge UIKit lifecycle events:

```swift
import SwiftUI
import Teak

@main
struct TeakSwiftCleanroomPodsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Teak.initSwiftUI(forApplicationId: "<YOUR_APP_ID>", andApiKey: "<YOUR_API_KEY>")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Player Login and Properties

Call `Teak.login` to identify the current player. Use your game's existing player ID — the same one your backend uses to store progress.

```swift
Teak.login("<YOUR_PLAYER_ID>", with: TeakUserConfiguration())
Teak.setStringProperty("favorite_slot", value: "demo")
Teak.setNumberProperty("bankroll", value: 12345)
```

### Push Notification Permissions

This example requests permissions at launch for simplicity. In a production app, request permissions at a contextually appropriate moment (e.g. after the player has had a chance to engage with the game):

```swift
Teak.requestNotificationPermissions { accepted, error in
    print("Player accepted notifications: \(accepted)")
}
```

### Deep Links

Register routes to handle deep links sent via Teak notifications:

```swift
Teak.registerDeepLinkRoute("/slots/:slot_name", name: "Go to Slot",
    description: "Take the player directly to a slot") { params in
    print("Taking the player to \(params["slot_name"]!)")
}
```

### Reward Handling

Observe `TeakOnReward` notifications to process rewards attached to push notifications:

```swift
NotificationCenter.default.addObserver(
    forName: Notification.Name(TeakOnReward), object: nil, queue: nil) { notification in
    let status = notification.userInfo!["status"] as! String
    switch status {
    case "grant_reward":  print("Reward Granted!")
    case "already_clicked": print("Already claimed!")
    default: break
    }
}
```

## Notification Extensions

Teak uses two notification extensions for rich push support. Both are thin subclasses that delegate to the SDK — the Teak framework handles the heavy lifting.

### Notification Service Extension

Processes incoming push payloads (e.g. decryption, media attachment downloads):

```swift
import TeakExtension

class NotificationService: TeakNotificationServiceCore {
    override func serviceExtensionTimeWillExpire() {
        super.serviceExtensionTimeWillExpire()
    }
}
```

### Notification Content Extension

Renders rich, interactive notification UI:

```swift
import TeakExtension

class NotificationViewController: TeakNotificationViewControllerCore {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
```

Both extension targets use the `Teak/Extension` subspecs in the Podfile:

```ruby
target 'TeakNotificationService' do
  use_frameworks!
  pod 'Teak/Extension'
end

target 'TeakContentExtension' do
  use_frameworks!
  pod 'Teak/Extension'
end
```

For the full walkthrough on creating these extensions, see [Install the Teak SDK (CocoaPods)](https://docs.teak.io/ios/latest/quickstart/install-sdk-cocoapods.html).

## Project Configuration Checklist

When adapting this example for your own app, verify:

- **Push Notifications capability** is enabled (creates the `.entitlements` file with `aps-environment`)
- **Background Modes** — "Remote notifications" is checked in Info.plist
- **URL Scheme** — `teak<YOUR_APP_ID>` is added under URL Types in your target's Info tab
- **Credentials** — Your App ID and API Key from the [Teak dashboard](https://app.teak.io) are set in your `App.init()`
- **Player ID** — `Teak.login` is called with your game's unique player identifier

## Sending Your First Notification

Once the app is running and you've granted notification permissions, follow the [Sending Your First Notification](https://docs.teak.io/ios/latest/quickstart/hello-world.html) guide to verify everything is working end-to-end.

## Further Reading

- [Teak iOS Quickstart Guide](https://docs.teak.io/ios/latest/quickstart/index.html)
- [Teak Dashboard](https://app.teak.io)

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
