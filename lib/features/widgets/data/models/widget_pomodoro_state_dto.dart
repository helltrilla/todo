import 'package:todo/features/widgets/domain/entities/widget_pomodoro_state.dart';

/// Data transfer object extending/mapping [WidgetPomodoroState] with JSON serialization.
class WidgetPomodoroStateDto extends WidgetPomodoroState {
  const WidgetPomodoroStateDto({
    required super.isRunning,
    required super.remainingSeconds,
    required super.totalSeconds,
    required super.mode,
    required super.completedPomodoros,
  });

  factory WidgetPomodoroStateDto.fromDomain(WidgetPomodoroState state) {
    return WidgetPomodoroStateDto(
      isRunning: state.isRunning,
      remainingSeconds: state.remainingSeconds,
      totalSeconds: state.totalSeconds,
      mode: state.mode,
      completedPomodoros: state.completedPomodoros,
    );
  }

  factory WidgetPomodoroStateDto.fromMap(Map<String, dynamic> map) {
    return WidgetPomodoroStateDto(
      isRunning: (map['isRunning'] as bool?) ?? false,
      remainingSeconds: (map['remainingSeconds'] as num?)?.toInt() ?? 1500,
      totalSeconds: (map['totalSeconds'] as num?)?.toInt() ?? 1500,
      mode: map['mode'] as String? ?? 'focus',
      completedPomodoros: (map['completedPomodoros'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isRunning': isRunning,
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'mode': mode,
      'completedPomodoros': completedPomodoros,
      'formattedRemaining': formattedRemaining,
      'progressFraction': progressFraction,
    };
  }
}
