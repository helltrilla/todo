import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/notifications/notification_service.dart';

/// Event-driven, battery-friendly service managing system media playback state
/// (Spotify, Apple Music, Yandex Music, etc.) and volume.
///
/// Replaces active constant polling with an event-driven stream and smart
/// foreground-only checks that shut down completely during pause or app sleep.
class MediaPlaybackService extends ChangeNotifier {
  final INotificationService _notificationService;

  bool _isPlaying = false;
  double _systemVolume = 0.65;
  bool _isAppForeground = true;
  Timer? _smartPollTimer;

  final StreamController<bool> _playbackStreamController =
      StreamController<bool>.broadcast();
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  MediaPlaybackService({INotificationService? notificationService})
    : _notificationService =
          notificationService ?? NotificationServiceImpl() {
    // Initial fetch
    unawaited(refreshPlaybackState());
    unawaited(refreshSystemVolume());
  }

  /// Whether external music player is actively playing.
  bool get isPlaying => _isPlaying;

  /// Current device hardware media volume (0.0 to 1.0).
  double get systemVolume => _systemVolume;

  /// Pure reactive broadcast stream of playback state changes.
  Stream<bool> get playbackStream => _playbackStreamController.stream;

  /// ValueListenable for declarative UI bindings (e.g., ValueListenableBuilder).
  ValueListenable<bool> get isPlayingListenable => _isPlayingNotifier;

  /// Checks the native OS audio manager state and updates listeners if changed.
  Future<void> refreshPlaybackState() async {
    final active = await _notificationService.getMediaPlaybackState();
    _applyPlaybackState(active);
  }

  /// Reads hardware media output volume from native platform channel.
  Future<void> refreshSystemVolume() async {
    final vol = await _notificationService.getSystemVolume();
    if (_systemVolume != vol) {
      _systemVolume = vol;
      notifyListeners();
    }
  }

  /// Toggles play/pause state event-driven with optimistic UI update
  /// and verified synchronization.
  Future<void> togglePlayPause() async {
    AppHaptics.medium();
    final nextState = !_isPlaying;
    _applyPlaybackState(nextState);

    unawaited(
      _notificationService.sendMediaCommand(nextState ? 'play' : 'pause'),
    );

    // One-shot verification after the platform audio session responds
    Future.delayed(const Duration(milliseconds: 350), refreshPlaybackState);
  }

  /// Sets hardware media volume.
  Future<void> setSystemVolume(double vol) async {
    final clamped = vol.clamp(0.0, 1.0);
    _systemVolume = clamped;
    notifyListeners();
    await _notificationService.setSystemVolume(clamped);
  }

  /// Called when the app enters foreground.
  Future<void> onAppResumed() async {
    _isAppForeground = true;
    await refreshPlaybackState();
    await refreshSystemVolume();
  }

  /// Called when the app enters background — immediately kills any active poll timer.
  void onAppPaused() {
    _isAppForeground = false;
    _stopSmartPoll();
  }

  /// Notification when user tapped an external playlist deep link.
  void onExternalLinkLaunched() {
    Future.delayed(const Duration(milliseconds: 1000), refreshPlaybackState);
  }

  void _applyPlaybackState(bool active) {
    if (_isPlaying != active) {
      _isPlaying = active;
      _isPlayingNotifier.value = active;
      _playbackStreamController.add(active);
      notifyListeners();
    }

    _syncSmartPolling();
  }

  /// Smart polling: ONLY runs when playback is active AND app is in foreground.
  /// Stops completely when paused or backgrounded to eliminate battery drain.
  void _syncSmartPolling() {
    if (_isPlaying && _isAppForeground) {
      if (_smartPollTimer == null || !_smartPollTimer!.isActive) {
        _smartPollTimer = Timer.periodic(
          const Duration(milliseconds: 4000),
          (_) => refreshPlaybackState(),
        );
      }
    } else {
      _stopSmartPoll();
    }
  }

  void _stopSmartPoll() {
    _smartPollTimer?.cancel();
    _smartPollTimer = null;
  }

  @override
  void dispose() {
    _stopSmartPoll();
    _playbackStreamController.close();
    _isPlayingNotifier.dispose();
    super.dispose();
  }
}
