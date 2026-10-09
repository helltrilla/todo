import AppIntents
import Foundation
import WidgetKit

/// Interactive AppIntent introduced in iOS 17 allowing users to mark tasks
/// as completed directly on the Home Screen without opening the app.
@available(iOS 17.0, *)
struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Переключить статус задачи"
    static var description = IntentDescription("Отмечает задачу выполненной прямо с виджета.")

    @Parameter(title: "ID задачи")
    var taskId: Int

    init() {}

    init(taskId: Int) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        let appGroup = "group.com.helltrilla.todoapp"
        let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard

        // 1. Record ID in pending queue for Flutter app sync
        var pending = defaults.array(forKey: "widget_pending_toggled_ids") as? [Int] ?? []
        if !pending.contains(taskId) {
            pending.append(taskId)
            defaults.set(pending, forKey: "widget_pending_toggled_ids")
        }

        // 2. Optimistically update cached snapshot in UserDefaults so widget UI reflects instantly
        if let data = defaults.data(forKey: "widget_snapshot_data"),
           var json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
           var tasks = json["tasks"] as? [[String: Any]] {
            for i in 0..<tasks.count {
                if (tasks[i]["id"] as? Int) == taskId {
                    let currentVal = tasks[i]["isCompleted"] as? Bool ?? false
                    tasks[i]["isCompleted"] = !currentVal
                }
            }
            json["tasks"] = tasks
            if let updatedData = try? JSONSerialization.data(withJSONObject: json, options: []) {
                defaults.set(updatedData, forKey: "widget_snapshot_data")
            }
        }
        defaults.synchronize()

        // 3. Immediately refresh widget timelines
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
