import WidgetKit
import SwiftUI

/// Entry point for the Live Activity widget extension.
///
/// The WidgetBundle must list an ActivityConfiguration for every
/// ActivityAttributes type the app supports. Each configuration maps
/// a data model to its Lock Screen and Dynamic Island presentations.
@main
struct TeakLiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivity()
        CountdownLiveActivity()
    }
}
