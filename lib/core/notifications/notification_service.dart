import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Cross-platform local push notification service backed by native
/// `UNUserNotificationCenter` on iOS and `NotificationManager` on Android.
///
/// For every uncompleted task with a [Task.dueDate]:
/// 1. Automatically schedules a notification at the exact [Task.dueDate] moment.
/// 2. Optionally schedules an advance reminder at
///    `dueDate.subtract(Duration(minutes: reminderOffsetMinutes))` if configured.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const MethodChannel _channel = MethodChannel(
    'com.helltrilla.todoapp/notifications',
  );

  bool _initialized = false;

  /// Requests notification permissions from the OS.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      _initialized = true;
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Schedules (or updates) local notifications for [task]:
  /// - Cancels any previous notifications for [task.id].
  /// - If [task] is completed, archived, or has no [Task.dueDate], stops here.
  /// - Schedules the automatic notification at [Task.dueDate] (if in the future).
  /// - Schedules the advance reminder notification at
  ///   `dueDate - reminderOffsetMinutes` (if set and in the future).
  Future<void> syncTaskNotifications(Task task) async {
    if (kIsWeb) return;
    await cancelTaskNotifications(task.id);

    if (task.isCompleted || task.isArchived || task.dueDate == null) {
      return;
    }

    if (!_initialized) {
      await requestPermissions();
    }

    final now = DateTime.now();
    final due = task.dueDate!;

    // 1. Automatic notification at the exact moment of the task
    if (due.isAfter(now)) {
      final subtitle = task.value.trim().isNotEmpty
          ? task.value.trim()
          : 'Наступило время выполнения задачи в категории «${task.category}»';
      await _scheduleNative(
        notificationId: 'task_${task.id}_due',
        title: '⏰ Время задачи: ${task.name}',
        body: subtitle,
        scheduledAt: due,
      );
    }

    // 2. Advance reminder notification before the task (if selected by user)
    final offsetMinutes = task.reminderOffsetMinutes;
    if (offsetMinutes != null && offsetMinutes > 0) {
      final reminderTime = due.subtract(Duration(minutes: offsetMinutes));
      if (reminderTime.isAfter(now)) {
        final offsetLabel = Task.formatReminderOffset(offsetMinutes);
        final hh = due.hour.toString().padLeft(2, '0');
        final mm = due.minute.toString().padLeft(2, '0');
        final bodyText = task.value.trim().isNotEmpty
            ? '${task.value.trim()} (в $hh:$mm)'
            : 'Задача запланирована на $hh:$mm';
        await _scheduleNative(
          notificationId: 'task_${task.id}_rem',
          title: '🔔 Напоминание ($offsetLabel): ${task.name}',
          body: bodyText,
          scheduledAt: reminderTime,
        );
      }
    }
  }

  /// Cancels both the exact-time and advance-reminder notifications for [taskId].
  Future<void> cancelTaskNotifications(int taskId) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('cancelTaskNotifications', <String, dynamic>{
        'ids': <String>['task_${taskId}_due', 'task_${taskId}_rem'],
      });
    } catch (_) {}
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('cancelAllNotifications');
    } catch (_) {}
  }

  ValueChanged<String>? _quickActionHandler;

  /// Registers a callback for Home Screen Quick Actions (3D Touch / Haptic Touch):
  /// - `'add_task'` -> Open AddTaskSheet
  /// - `'open_focus'` -> Switch to Focus (Pomodoro) tab
  /// - `'open_calendar'` -> Switch to Calendar tab
  Future<void> registerQuickActionHandler(
    ValueChanged<String> onQuickAction,
  ) async {
    _quickActionHandler = onQuickAction;
    if (kIsWeb) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onQuickAction') {
        final actionType = call.arguments as String?;
        if (actionType != null && actionType.isNotEmpty) {
          _quickActionHandler?.call(actionType);
        }
      }
    });

    try {
      final initialAction = await _channel.invokeMethod<String>(
        'consumeInitialQuickAction',
      );
      if (initialAction != null && initialAction.isNotEmpty) {
        _quickActionHandler?.call(initialAction);
      }
    } catch (_) {}
  }

  /// Sends an immediate notification when a Pomodoro focus session finishes.
  Future<void> sendFocusCompletedNotification({String? taskName}) async {
    if (kIsWeb) return;
    final fireAt = DateTime.now().add(const Duration(seconds: 1));
    final body = (taskName != null && taskName.trim().isNotEmpty)
        ? 'Сессия фокуса по задаче «${taskName.trim()}» успешно завершена!'
        : 'Сессия фокуса успешно завершена! Время сделать небольшой перерыв.';
    await _scheduleNative(
      notificationId: 'todoapp_focus_complete',
      title: '🔥 Фокус-сессия завершена!',
      body: body,
      scheduledAt: fireAt,
    );
  }

  /// Sends an immediate test notification (after 2 seconds) to verify push setup.
  Future<bool> sendTestNotification() async {
    if (kIsWeb) return false;
    final granted = await requestPermissions();
    if (!granted) return false;

    final fireAt = DateTime.now().add(const Duration(seconds: 2));
    await _scheduleNative(
      notificationId: 'todoapp_test_push',
      title: '🔔 Уведомления TodoApp работают!',
      body: 'Вы получите напоминание заранее и в точный момент задачи.',
      scheduledAt: fireAt,
    );
    return true;
  }

  /// Opens the native system photo picker (with square crop on iOS) and returns
  /// the selected image encoded as a base64 JPEG string, or `null` if cancelled.
  Future<String?> pickProfileImage() async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<String>('pickProfileImage');
    } catch (_) {
      return null;
    }
  }

  Future<void> _scheduleNative({
    required String notificationId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    try {
      await _channel.invokeMethod<void>('scheduleNotification', <String, dynamic>{
        'id': notificationId,
        'title': title,
        'body': body,
        'timestampMs': scheduledAt.millisecondsSinceEpoch,
      });
    } catch (_) {}
  }
}
