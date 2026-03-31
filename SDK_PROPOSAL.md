# Teak Live Activity SDK Proposal

This document captures SDK integration boundary analysis from the Live Activity
reference implementation in this project. The code itself is a tutorial-style
implementation of iOS Live Activities; this document discusses where Teak could
plug in.

## Boundary Summary

| Layer | Owner | Notes |
|-------|-------|-------|
| **ActivityAttributes / ContentState types** | App | Always app-defined. The ContentState shape determines the push payload JSON and the widget must compile it. |
| **Widget UI (Lock Screen, Dynamic Island)** | App | SwiftUI in a widget extension. SDK could provide convenience views but can't own this. |
| **WidgetBundle registration** | App | Must explicitly list each ActivityConfiguration. Even if Teak managed everything else, the app still needs this file. |
| **Activity lifecycle (start/update/end)** | App or SDK | Could go either way. See "Lifecycle Wrapping" below. |
| **Per-activity push token collection** | SDK | Analogous to existing push notification token flow. Critical for server-driven updates. |
| **Push-to-start token collection** | SDK | Per-type device token for remote activity creation (iOS 17.2+). |
| **ContentState schema introspection** | SDK | Runtime discovery of the JSON payload shape the server needs. |
| **Token forwarding to backend** | SDK | Send tokens + schema to Teak backend for dashboard/API use. |
| **Activity state observation & analytics** | SDK | Lifecycle events, duration tracking, update counts. |

## ActivityAttributes Are Always App-Defined

An SDK cannot provide a universal ActivityAttributes type because:

1. The ContentState shape determines the push payload JSON — it must match exactly.
2. The widget extension must compile the type to render the UI.
3. Different apps have different Live Activity use cases.

An app can define **multiple** ActivityAttributes types. Each one gets:
- Its own push-to-start token (per-type, per-device)
- Its own per-instance activity push tokens
- Its own ContentState schema
- Its own ActivityConfiguration in the WidgetBundle

### Registration API Surface

```swift
// App registers each type at launch
Teak.register(TimerActivityAttributes.self)
Teak.register(CountdownActivityAttributes.self)
```

Each registration would trigger:
- Push-to-start token observation for that type
- Schema introspection and backend registration for that type
- A separate token forwarding channel per type

## Push Token Flow

### Per-Activity Push Tokens

When an activity is started with `pushType: .token`, iOS generates a unique
push token for that activity instance. Key details:

- Each activity instance gets its own unique token
- The token **may change** during the activity's lifetime — the server must
  update its records when this happens
- The token is tied to this device + this activity instance
- The token becomes invalid when the activity ends
- The server uses this token with APNs topic: `{bundle_id}.push-type.liveactivity`

The SDK would observe `activity.pushTokenUpdates` and forward tokens to the
Teak backend (analogous to the existing `PushRegistrationEvent` flow for
regular push tokens).

### Push-to-Start Tokens (iOS 17.2+)

Push-to-start tokens allow the server to create a new activity remotely,
without the app starting one first.

- These are **per-type**, not per-instance — one token covers all future
  activities of that type on this device
- The token persists across app launches (the system manages it)
- The device must have previously run code that observes this token for the
  system to generate one
- When the server sends a "start" push using this token, iOS creates the
  activity and wakes the app
- After push-to-start creates an activity, the app should observe
  `Activity<T>.activityUpdates` to discover the new instance and then
  observe its `pushTokenUpdates`

**Production pattern:** Push-to-start token observation should start at app
launch (e.g., in `application(_:didFinishLaunchingWithOptions:)`), not lazily.
The SDK would handle this automatically as part of `Teak.register(T.self)`.

### Token Forwarding

The SDK would forward tokens to the Teak backend:

```
POST /api/live_activity/register_token
{
  activity_id: "...",
  activity_type: "TimerActivityAttributes",
  push_token: "abc123...",
  content_state_schema: { ... }
}

POST /api/live_activity/register_push_to_start_token
{
  activity_type: "TimerActivityAttributes",
  push_to_start_token: "def456..."
}
```

## ContentState Schema Introspection

For push-based updates, the server must construct a `content-state` JSON
payload that exactly matches the app's ContentState struct. The SDK can
discover this shape at runtime:

**Mirror reflection** — given a ContentState instance, `Mirror(reflecting:)`
yields property names and runtime types.

**JSON encoding** — since ContentState conforms to Codable,
`JSONEncoder().encode(state)` produces the exact JSON shape the server needs.
This is the source of truth for the push payload.

The SDK would run introspection once at activity-start time and send the
discovered schema alongside the push token registration.

### Limitations

- Mirror gives runtime value types, not declared types (`Optional<String>`
  shows as `String` when non-nil)
- No way to get the schema from just the type without an instance
- Custom CodingKeys may cause Mirror property names to differ from JSON keys
  (JSON encoding is the source of truth)
- Nested Codable types need recursive inspection

### What the Backend Does With the Schema

- Dashboard shows a form with the correct fields for constructing update payloads
- Backend validates outgoing push payloads against the schema before sending
- API docs display the expected JSON shape per activity type

## Lifecycle Wrapping

The start/update/end operations could be wrapped by the SDK, but this is the
boundary most worth debating.

### Start

```swift
// Without SDK — app manages everything
let activity = try Activity.request(attributes: attrs, content: content, pushType: .token)
// ... manually observe tokens, introspect schema, forward to backend

// With SDK — Teak handles tokens + registration automatically
let activity = try Teak.startLiveActivity(attributes: attrs, content: content)
// SDK automatically: observes pushTokenUpdates, introspects schema,
// registers with backend, tracks for analytics
```

### Update

For **local** updates, the SDK wrapper adds analytics:
```swift
// Without SDK
await activity.update(content)

// With SDK
await Teak.updateLiveActivity(activity, content: content)
// SDK also notifies backend of state change for analytics
```

For **push-based** updates, the app doesn't call update at all — the server
sends an APNs push with the new content-state JSON, and iOS applies it
automatically. This is the primary use case for Teak integration.

### End

```swift
// Without SDK
await activity.end(content, dismissalPolicy: .immediate)

// With SDK
await Teak.endLiveActivity(activity, content: content, dismissalPolicy: .immediate)
// SDK also: revokes push token on backend (important — stale tokens waste
// APNs budget), emits analytics (duration, update count), cleans up tracking
```

Token revocation on end is particularly important. Stale tokens cause APNs
delivery failures and waste the app's push notification budget.

## Push Payload Reference

### Update Payload

```json
{
  "aps": {
    "timestamp": 1705560370,
    "event": "update",
    "content-state": {
      "endDate": "2025-01-18T12:06:10Z",
      "status": "Almost Done!"
    },
    "stale-date": 1705567570,
    "alert": {
      "title": "Optional alert title",
      "body": "Optional alert body"
    }
  }
}
```

### Start Payload (push-to-start, iOS 17.2+)

```json
{
  "aps": {
    "timestamp": 1705547770,
    "event": "start",
    "attributes-type": "TimerActivityAttributes",
    "attributes": {},
    "content-state": {
      "endDate": "2025-01-18T12:06:10Z",
      "status": "In Progress"
    },
    "alert": { "title": "...", "body": "..." }
  }
}
```

### End Payload

```json
{
  "aps": {
    "timestamp": 1705560370,
    "event": "end",
    "content-state": {
      "endDate": "2025-01-18T12:06:10Z",
      "status": "Complete"
    },
    "dismissal-date": 1705567570
  }
}
```

### APNs Headers

- `apns-push-type: liveactivity`
- `apns-topic: {bundle_id}.push-type.liveactivity`
- `apns-priority: 5` (low, no budget impact) or `10` (high, counts against budget)
- Authentication: **token-based (.p8) only** — certificate-based (.p12) not supported

## Open Questions

1. **Should the SDK own activity lifecycle (start/update/end)?** Or just token
   collection + forwarding, leaving lifecycle to the app?

2. **How should the dashboard construct ContentState payloads?** Schema
   introspection gives the field names and types, but the dashboard needs to
   know _what values_ to send. Is this fully manual, or can we provide
   templates/defaults?

3. **activityUpdates observation** — When push-to-start creates an activity,
   the app needs to discover it via `Activity<T>.activityUpdates`. Should the
   SDK manage this automatically as part of registration?

4. **Multiple concurrent activities** — iOS allows up to 5 per app. Should the
   SDK track all active instances, or just the tokens?
