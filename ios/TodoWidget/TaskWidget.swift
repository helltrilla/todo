import SwiftUI
import WidgetKit

// MARK: - Widget Data Models

struct WidgetTask: Identifiable, Decodable {
    let id: Int
    let title: String
    let isCompleted: Bool
    let priorityIndex: Int
    let category: String
    let dueDateLabel: String?

    var priorityColor: Color {
        switch priorityIndex {
        case 0: return Color(red: 0.94, green: 0.27, blue: 0.27) // P1 Red
        case 1: return Color(red: 0.96, green: 0.62, blue: 0.15) // P2 Orange/Yellow
        case 2: return Color(red: 0.24, green: 0.55, blue: 0.95) // P3 Blue
        case 3: return Color(red: 0.45, green: 0.50, blue: 0.58) // P4 Gray
        default: return Color(red: 0.45, green: 0.50, blue: 0.58)
        }
    }
}

struct TaskWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let pendingCount: Int
    let completedCount: Int
}

// MARK: - Timeline Provider

struct TaskTimelineProvider: TimelineProvider {
    private let appGroup = "group.com.helltrilla.todoapp"

    func placeholder(in context: Context) -> TaskWidgetEntry {
        TaskWidgetEntry(
            date: Date(),
            tasks: [
                WidgetTask(id: 1, title: "Завершить презентацию", isCompleted: false, priorityIndex: 0, category: "Работа", dueDateLabel: "14:00"),
                WidgetTask(id: 2, title: "Купить продукты", isCompleted: false, priorityIndex: 1, category: "Личное", dueDateLabel: "18:30"),
                WidgetTask(id: 3, title: "Фокус-сессия 25 минут", isCompleted: true, priorityIndex: 2, category: "Учеба", dueDateLabel: nil)
            ],
            pendingCount: 2,
            completedCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskWidgetEntry) -> Void) {
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskWidgetEntry>) -> Void) {
        let entry = loadCurrentEntry()
        // Refresh periodically every 30 minutes or when triggered by Flutter / AppIntent
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCurrentEntry() -> TaskWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
        guard let data = defaults.data(forKey: "widget_snapshot_data"),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return placeholder(in: Context())
        }

        let pendingCount = json["pendingCount"] as? Int ?? 0
        let completedCount = json["completedCount"] as? Int ?? 0

        var parsedTasks: [WidgetTask] = []
        if let rawTasks = json["tasks"] as? [[String: Any]] {
            for t in rawTasks {
                if let id = t["id"] as? Int,
                   let title = t["title"] as? String {
                    let isCompleted = t["isCompleted"] as? Bool ?? false
                    let priorityIndex = t["priorityIndex"] as? Int ?? -1
                    let category = t["category"] as? String ?? "Общее"
                    let due = t["dueDateLabel"] as? String
                    parsedTasks.append(
                        WidgetTask(
                            id: id,
                            title: title,
                            isCompleted: isCompleted,
                            priorityIndex: priorityIndex,
                            category: category,
                            dueDateLabel: due
                        )
                    )
                }
            }
        }

        return TaskWidgetEntry(
            date: Date(),
            tasks: parsedTasks,
            pendingCount: pendingCount,
            completedCount: completedCount
        )
    }
}

// MARK: - Widget View

struct TaskWidgetView: View {
    let entry: TaskWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.09, blue: 0.12).ignoresSafeArea() // #12171F

            switch family {
            case .systemSmall:
                SmallTaskView(entry: entry)
            case .systemLarge:
                LargeTaskView(entry: entry)
            default:
                MediumTaskView(entry: entry)
            }
        }
    }
}

// MARK: - Layout Variants

struct SmallTaskView: View {
    let entry: TaskWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(Color(red: 0.96, green: 0.79, blue: 0.05))
                    .font(.system(size: 15, weight: .bold))
                Text("TodoApp")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.pendingCount)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("задач в работе")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }

            if let nextTask = entry.tasks.first(where: { !$0.isCompleted }) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(nextTask.priorityColor)
                        .frame(width: 6, height: 6)
                    Text(nextTask.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
            }
        }
        .padding(14)
    }
}

struct MediumTaskView: View {
    let entry: TaskWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(Color(red: 0.96, green: 0.79, blue: 0.05))
                    .font(.system(size: 14, weight: .bold))
                Text("Мои задачи")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(entry.pendingCount) в работе")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.96, green: 0.79, blue: 0.05))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.96, green: 0.79, blue: 0.05).opacity(0.12))
                    .cornerRadius(8)
            }
            .padding(.bottom, 2)

            if entry.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Все задачи выполнены! 🎉")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 5) {
                    ForEach(entry.tasks.prefix(3)) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
        .padding(14)
    }
}

struct LargeTaskView: View {
    let entry: TaskWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .foregroundColor(Color(red: 0.96, green: 0.79, blue: 0.05))
                        .font(.system(size: 15, weight: .bold))
                    Text("TodoApp")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("\(entry.pendingCount) задач")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }

            Divider().background(Color.white.opacity(0.1))

            if entry.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Все задачи выполнены! 🎉")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 6) {
                    ForEach(entry.tasks.prefix(6)) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Interactive Task Row

struct TaskRowView: View {
    let task: WidgetTask

    var body: some View {
        HStack(spacing: 10) {
            // Interactive checkbox in iOS 17+, or deep-link toggle fallback
            if #available(iOS 17.0, *) {
                Button(intent: ToggleTaskIntent(taskId: task.id)) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(task.isCompleted ? Color(red: 0.30, green: 0.75, blue: 0.40) : .gray)
                }
                .buttonStyle(.plain)
            } else {
                Link(destination: URL(string: "todoapp://toggle?id=\(task.id)")!) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(task.isCompleted ? Color(red: 0.30, green: 0.75, blue: 0.40) : .gray)
                }
            }

            Circle()
                .fill(task.priorityColor)
                .frame(width: 5, height: 5)

            Text(task.title)
                .font(.system(size: 12, weight: task.isCompleted ? .regular : .semibold))
                .foregroundColor(task.isCompleted ? .gray : .white)
                .strikethrough(task.isCompleted, color: .gray)
                .lineLimit(1)

            Spacer()

            if let due = task.dueDateLabel {
                Text(due)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.96, green: 0.79, blue: 0.05).opacity(0.85))
            } else {
                Text(task.category)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }
}

// MARK: - TaskWidget Declaration

struct TaskWidget: Widget {
    let kind: String = "com.helltrilla.todoapp.TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskTimelineProvider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("Задачи")
        .description("Список актуальных задач с интерактивными чекбоксами (iOS 17+).")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
