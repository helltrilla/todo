/// Pure Dart domain entity representing the Pomodoro timer state for widgets.
/// Contains ZERO Flutter imports and ZERO serialization methods.
class WidgetPomodoroState {
  const WidgetPomodoroState({
    required this.isRunning,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.mode,
    required this.completedPomodoros,
  });

  final bool isRunning;
  final int remainingSeconds;
  final int totalSeconds;
  final String mode; // 'focus', 'shortBreak', 'longBreak'
  final int completedPomodoros;

  double get progressFraction {
    if (totalSeconds <= 0) return 0.0;
    return (totalSeconds - remainingSeconds).clamp(0, totalSeconds) /
        totalSeconds;
  }

  String get formattedRemaining {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static const idle = WidgetPomodoroState(
    isRunning: false,
    remainingSeconds: 25 * 60,
    totalSeconds: 25 * 60,
    mode: 'focus',
    completedPomodoros: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetPomodoroState &&
          runtimeType == other.runtimeType &&
          isRunning == other.isRunning &&
          remainingSeconds == other.remainingSeconds &&
          totalSeconds == other.totalSeconds &&
          mode == other.mode &&
          completedPomodoros == other.completedPomodoros;

  @override
  int get hashCode => Object.hash(
    isRunning,
    remainingSeconds,
    totalSeconds,
    mode,
    completedPomodoros,
  );
}
