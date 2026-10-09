import SwiftUI
import WidgetKit

// MARK: - Pomodoro Lock Screen Models & Entry

struct PomodoroWidgetEntry: TimelineEntry {
    let date: Date
    let isRunning: Bool
    let remainingSeconds: Int
    let totalSeconds: Int
    let mode: String
    let completedPomodoros: Int
    let nextTaskTitle: String?

    var progressFraction: Double {
        guard totalSeconds > 0 else { return 0.0 }
        let elapsed = max(0, totalSeconds - remainingSeconds)
        return min(1.0, Double(elapsed) / Double(totalSeconds))
    }

    var formattedMinutes: String {
        let m = remainingSeconds / 60
        return "\(m)м"
    }

    var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Pomodoro Timeline Provider

struct PomodoroTimelineProvider: TimelineProvider {
    private let appGroup = "group.com.helltrilla.todoapp"

    func placeholder(in context: Context) -> PomodoroWidgetEntry {
        PomodoroWidgetEntry(
            date: Date(),
            isRunning: true,
            remainingSeconds: 22 * 60,
            totalSeconds: 25 * 60,
            mode: "focus",
            completedPomodoros: 3,
            nextTaskTitle: "Фокус-сессия"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PomodoroWidgetEntry) -> Void) {
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PomodoroWidgetEntry>) -> Void) {
        let entry = loadCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCurrentEntry() -> PomodoroWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
        guard let data = defaults.data(forKey: "widget_snapshot_data"),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return placeholder(in: Context())
        }

        let pomodoro = json["pomodoro"] as? [String: Any] ?? [:]
        let isRunning = pomodoro["isRunning"] as? Bool ?? false
        let remainingSeconds = pomodoro["remainingSeconds"] as? Int ?? 1500
        let totalSeconds = pomodoro["totalSeconds"] as? Int ?? 1500
        let mode = pomodoro["mode"] as? String ?? "focus"
        let completedPomodoros = pomodoro["completedPomodoros"] as? Int ?? 0

        var nextTaskTitle: String?
        if let rawTasks = json["tasks"] as? [[String: Any]] {
            for t in rawTasks {
                if let isCompleted = t["isCompleted"] as? Bool, !isCompleted,
                   let title = t["title"] as? String {
                    nextTaskTitle = title
                    break
                }
            }
        }

        return PomodoroWidgetEntry(
            date: Date(),
            isRunning: isRunning,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            mode: mode,
            completedPomodoros: completedPomodoros,
            nextTaskTitle: nextTaskTitle
        )
    }
}

// MARK: - Lock Screen Widget View

struct PomodoroLockScreenWidgetView: View {
    let entry: PomodoroWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularPomodoroView(entry: entry)
        case .accessoryRectangular:
            RectangularPomodoroView(entry: entry)
        case .accessoryInline:
            InlinePomodoroView(entry: entry)
        default:
            CircularPomodoroView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Accessory Views

struct CircularPomodoroView: View {
    let entry: PomodoroWidgetEntry

    var body: some View {
        Gauge(value: entry.progressFraction, in: 0...1) {
            Image(systemName: "timer")
        } currentValueLabel: {
            Text(entry.formattedMinutes)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct RectangularPomodoroView: View {
    let entry: PomodoroWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: entry.isRunning ? "play.circle.fill" : "pause.circle")
                    .font(.system(size: 12, weight: .bold))
                Text(entry.isRunning ? "Фокус: \(entry.formattedTime)" : "Помодоро: Пауза")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Text("🍅 \(entry.completedPomodoros)")
                    .font(.system(size: 11, weight: .semibold))
            }

            if let task = entry.nextTaskTitle {
                Text(task)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("Нет активных задач")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ProgressView(value: entry.progressFraction)
                .progressViewStyle(.linear)
        }
    }
}

struct InlinePomodoroView: View {
    let entry: PomodoroWidgetEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text("🍅 \(entry.formattedMinutes)")
            if let task = entry.nextTaskTitle {
                Text("• \(task)")
            }
        }
    }
}

// MARK: - PomodoroLockScreenWidget Declaration

struct PomodoroLockScreenWidget: Widget {
    let kind: String = "com.helltrilla.todoapp.PomodoroLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroTimelineProvider()) { entry in
            PomodoroLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Помодоро & Фокус")
        .description("Таймер режима фокуса и ближайшая задача на экране блокировки.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
