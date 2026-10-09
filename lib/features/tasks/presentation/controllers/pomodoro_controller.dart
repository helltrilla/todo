import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/notifications/notification_service.dart';

/// Presentation state controller managing the Pomodoro Focus Timer.
/// Decoupled from task CRUD logic in adherence with Single Responsibility Principle.
class PomodoroController extends ChangeNotifier {
  PomodoroController({
    SharedPreferences? prefs,
    INotificationService? notificationService,
    this.onSessionFinished,
    this.onStateChanged,
  }) : _prefs = prefs,
       _notificationService =
           notificationService ?? NotificationServiceImpl() {
    _loadSelectedMinutes();
  }

  static const List<int> presetsMinutes = [15, 25, 45, 60];
  static const String _focusSelectedMinutesKey = 'focus_selected_minutes';

  final SharedPreferences? _prefs;
  final INotificationService _notificationService;

  /// Optional callback invoked when a focus session completes.
  /// Receives [taskId] (if any) and duration in [minutes].
  final Future<void> Function(int? taskId, int minutes, String? taskName)?
      onSessionFinished;

  /// Optional callback invoked whenever timer state changes (e.g. for widget sync).
  final void Function(bool isRunning, int remainingSeconds, int totalSeconds)?
      onStateChanged;

  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  int? _focusedTaskId;
  String? _focusedTaskName;
  int _completedSessions = 0;
  int _totalFocusMinutesRecorded = 0;

  int get selectedMinutes => _selectedMinutes;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _selectedMinutes * 60;
  bool get isRunning => _isRunning;
  int? get focusedTaskId => _focusedTaskId;
  String? get focusedTaskName => _focusedTaskName;
  int get completedSessions => _completedSessions;
  int get totalFocusMinutesRecorded => _totalFocusMinutesRecorded;
  INotificationService get notificationService => _notificationService;

  @visibleForTesting
  Future<void> completeSessionForTesting() => _onSessionCompleted();

  double get progress {
    final total = totalSeconds;
    if (total <= 0) return 0.0;
    return (_remainingSeconds / total).clamp(0.0, 1.0);
  }

  String get formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _loadSelectedMinutes() {
    final saved = _prefs?.getInt(_focusSelectedMinutesKey);
    if (saved != null && saved > 0 && !_isRunning) {
      _selectedMinutes = saved;
      _remainingSeconds = saved * 60;
      notifyListeners();
    }
  }

  Future<void> selectPreset(int minutes) async {
    if (minutes <= 0) return;
    AppHaptics.selection();
    _timer?.cancel();
    _selectedMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _isRunning = false;
    notifyListeners();
    onStateChanged?.call(false, _remainingSeconds, totalSeconds);
    await _prefs?.setInt(_focusSelectedMinutesKey, minutes);
  }

  Future<void> setCustomDuration(int minutes) async {
    await selectPreset(minutes);
  }

  void setFocusedTaskId(int? taskId, {String? taskName}) {
    if (_focusedTaskId == taskId && _focusedTaskName == taskName) return;
    _focusedTaskId = taskId;
    _focusedTaskName = taskName;
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      pause();
    } else {
      start();
    }
  }

  void start() {
    if (_isRunning) return;
    AppHaptics.medium();
    _isRunning = true;
    notifyListeners();
    onStateChanged?.call(true, _remainingSeconds, totalSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _onSessionCompleted();
      } else {
        _remainingSeconds--;
        notifyListeners();
        onStateChanged?.call(true, _remainingSeconds, totalSeconds);
      }
    });
  }

  void pause() {
    if (!_isRunning) return;
    AppHaptics.medium();
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
    onStateChanged?.call(false, _remainingSeconds, totalSeconds);
  }

  void reset() {
    AppHaptics.light();
    _timer?.cancel();
    _remainingSeconds = _selectedMinutes * 60;
    _isRunning = false;
    notifyListeners();
    onStateChanged?.call(false, _remainingSeconds, totalSeconds);
  }

  Future<void> _onSessionCompleted() async {
    AppHaptics.heavy();
    _remainingSeconds = 0;
    _isRunning = false;
    _completedSessions++;
    _totalFocusMinutesRecorded += _selectedMinutes;
    notifyListeners();
    onStateChanged?.call(false, 0, totalSeconds);

    final taskId = _focusedTaskId;
    final taskName = _focusedTaskName;
    final minutes = _selectedMinutes;

    unawaited(
      _notificationService.sendFocusCompletedNotification(
        taskName: taskName,
      ),
    );

    if (onSessionFinished != null) {
      await onSessionFinished!(taskId, minutes, taskName);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
