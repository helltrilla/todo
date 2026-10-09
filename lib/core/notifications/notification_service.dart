import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

/// Abstract interface for push notifications, quick actions,
/// background media transport controls, and device audio utilities.
abstract interface class INotificationService {
  /// Initializes notification service and requests permissions.
  Future<bool> initialize();

  /// Requests notification permissions from the OS.
  Future<bool> requestPermissions();

  /// Schedules (or updates) local notifications for [task].
  Future<void> syncTaskNotifications(Task task);

  /// Alias for [syncTaskNotifications].
  Future<void> scheduleTaskNotification(Task task);

  /// Cancels both exact-time and advance-reminder notifications for [taskId].
  Future<void> cancelTaskNotifications(int taskId);

  /// Cancels notifications for [id].
  Future<void> cancelNotification(int id);

  /// Cancels all scheduled local notifications.
  Future<void> cancelAllNotifications();

  /// Cancels all scheduled local notifications.
  Future<void> cancelAll();

  /// Registers a callback for Home Screen Quick Actions (3D Touch / Haptic Touch).
  Future<void> registerQuickActionHandler(ValueChanged<String> onQuickAction);

  /// Sends an immediate notification when a Pomodoro focus session finishes.
  Future<void> sendFocusCompletedNotification({String? taskName});

  /// Sends an immediate test notification to verify push configuration.
  Future<bool> sendTestNotification();

  /// Opens the native platform photo picker and returns selected base64 image.
  Future<String?> pickProfileImage();

  /// Configures procedural background ambient soundscape playback.
  Future<void> setAmbientSound({
    required String sound,
    double volume = 0.45,
  });

  /// Opens a deep link or external URL in the target app or web browser.
  Future<bool> openExternalUrl({
    required String url,
    String? fallbackUrl,
  });

  /// Dispatches a system media transport command (`previous`, `playPause`, `next`).
  Future<void> sendMediaCommand(String command);

  /// Returns true if external media player is actively playing.
  Future<bool> getMediaPlaybackState();

  /// Reads current hardware media volume (0.0 to 1.0).
  Future<double> getSystemVolume();

  /// Sets hardware media volume (0.0 to 1.0).
  Future<void> setSystemVolume(double volume);
}

/// Cross-platform implementation of [INotificationService] backed by native
/// platform channels (`com.helltrilla.todoapp/notifications`).
class NotificationServiceImpl implements INotificationService {
  final MethodChannel _channel;
  bool _initialized = false;
  ValueChanged<String>? _quickActionHandler;

  NotificationServiceImpl({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('com.helltrilla.todoapp/notifications');

  @override
  Future<bool> initialize() => requestPermissions();

  @override
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

  @override
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

    // 1. Exact-moment task notification
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

    // 2. Advance reminder notification
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

  @override
  Future<void> scheduleTaskNotification(Task task) => syncTaskNotifications(task);

  @override
  Future<void> cancelTaskNotifications(int taskId) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>(
        'cancelTaskNotifications',
        <String, dynamic>{
          'ids': <String>['task_${taskId}_due', 'task_${taskId}_rem'],
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> cancelNotification(int id) => cancelTaskNotifications(id);

  @override
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('cancelAllNotifications');
    } catch (_) {}
  }

  @override
  Future<void> cancelAll() => cancelAllNotifications();

  @override
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

  @override
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

  @override
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

  @override
  Future<String?> pickProfileImage() async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<String>('pickProfileImage');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setAmbientSound({
    required String sound,
    double volume = 0.45,
  }) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setAmbientSound', <String, dynamic>{
        'sound': sound,
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (_) {}
  }

  @override
  Future<bool> openExternalUrl({
    required String url,
    String? fallbackUrl,
  }) async {
    if (kIsWeb) {
      final target =
          Uri.tryParse(url) ??
          (fallbackUrl != null ? Uri.tryParse(fallbackUrl) : null);
      if (target != null) {
        try {
          return await ul.launchUrl(
            target,
            mode: ul.LaunchMode.externalApplication,
          );
        } catch (_) {
          return false;
        }
      }
      return false;
    }
    try {
      final opened = await _channel.invokeMethod<bool>(
        'openExternalUrl',
        <String, dynamic>{'url': url, 'fallbackUrl': fallbackUrl},
      );
      if (opened == true) return true;
    } catch (_) {}

    // Fallback if platform channel failed to handle the URI
    final target = Uri.tryParse(fallbackUrl ?? url);
    if (target != null) {
      try {
        return await ul.launchUrl(
          target,
          mode: ul.LaunchMode.externalApplication,
        );
      } catch (_) {}
    }
    return false;
  }

  @override
  Future<void> sendMediaCommand(String command) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('sendMediaCommand', <String, dynamic>{
        'command': command,
      });
    } catch (_) {}
  }

  @override
  Future<bool> getMediaPlaybackState() async {
    if (kIsWeb) return false;
    try {
      final playing = await _channel.invokeMethod<bool>(
        'getMediaPlaybackState',
      );
      return playing ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<double> getSystemVolume() async {
    if (kIsWeb) return 0.65;
    try {
      final vol = await _channel.invokeMethod<double>('getSystemVolume');
      return (vol ?? 0.65).clamp(0.0, 1.0);
    } catch (_) {
      return 0.65;
    }
  }

  @override
  Future<void> setSystemVolume(double volume) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setSystemVolume', <String, dynamic>{
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (_) {}
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

/// Convenience typedef for backward-compatible DI references.
typedef NotificationService = NotificationServiceImpl;
