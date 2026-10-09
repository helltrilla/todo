import 'dart:async';
import 'package:flutter/services.dart';

/// Native DataSource handling low-level communication with iOS WidgetKit / App Groups.
class WidgetNativeDataSource {
  WidgetNativeDataSource({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.helltrilla.todoapp/widgets') {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final StreamController<int> _toggledTaskStreamController =
      StreamController<int>.broadcast();

  Stream<int> get toggledTaskStream => _toggledTaskStreamController.stream;

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onWidgetTaskToggled') {
      final taskId = (call.arguments as num?)?.toInt();
      if (taskId != null) {
        _toggledTaskStreamController.add(taskId);
      }
    }
  }

  /// Pushes serialized widget payload to native UserDefaults / WidgetCenter.
  Future<void> syncWidgetData(Map<String, dynamic> payload) async {
    await _channel.invokeMethod('syncWidgetData', payload);
  }

  /// Retrieves list of task IDs that were toggled while Flutter engine was not running.
  Future<List<int>> getPendingToggledTaskIds() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getPendingToggledTaskIds',
    );
    if (result == null) return const [];
    return result.whereType<num>().map((e) => e.toInt()).toList();
  }

  /// Clears pending toggled task IDs after successful application.
  Future<void> clearPendingToggledTaskIds() async {
    await _channel.invokeMethod('clearPendingToggledTaskIds');
  }

  void dispose() {
    _toggledTaskStreamController.close();
  }
}
