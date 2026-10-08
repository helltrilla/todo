import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized tactile feedback helper for iOS Taptic Engine & Android vibration.
class AppHaptics {
  AppHaptics._();

  static bool enabled = true;

  /// Crisp selection tick for picker wheels, tab switches, and filter chips.
  static void selection() {
    if (kIsWeb || !enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Soft impact for subtask checkboxes, priority selection, and minor toggles.
  static void light() {
    if (kIsWeb || !enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Distinct impact for task completion, saving a task, and starting Focus mode.
  static void medium() {
    if (kIsWeb || !enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Strong impact for swipe-to-archive, swipe-to-delete, and timer completion.
  static void heavy() {
    if (kIsWeb || !enabled) return;
    HapticFeedback.heavyImpact();
  }
}
