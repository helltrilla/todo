import SwiftUI
import WidgetKit

/// Main WidgetBundle registering both Home Screen task widgets and Lock Screen Pomodoro widgets.
@main
struct TodoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
        PomodoroLockScreenWidget()
    }
}
