import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/domain/entities/ambient_sound.dart';
import 'package:todo/features/ambient/domain/usecases/get_ambient_presets_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/pause_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/play_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/set_ambient_volume_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/stop_ambient_sound_use_case.dart';

/// Presentation state controller managing Ambient Soundscapes.
/// Interacts STRICTLY with Use Cases; never touches repositories or data sources directly.
class AmbientAudioController extends ChangeNotifier {
  AmbientAudioController({
    required GetAmbientPresetsUseCase getPresetsUseCase,
    required PlayAmbientSoundUseCase playUseCase,
    required PauseAmbientSoundUseCase pauseUseCase,
    required StopAmbientSoundUseCase stopUseCase,
    required SetAmbientVolumeUseCase setVolumeUseCase,
    Stream<dynamic>? externalStateStream,
  }) : _getPresetsUseCase = getPresetsUseCase,
       _playUseCase = playUseCase,
       _pauseUseCase = pauseUseCase,
       _stopUseCase = stopUseCase,
       _setVolumeUseCase = setVolumeUseCase {
    _init(externalStateStream);
  }

  final GetAmbientPresetsUseCase _getPresetsUseCase;
  final PlayAmbientSoundUseCase _playUseCase;
  final PauseAmbientSoundUseCase _pauseUseCase;
  final StopAmbientSoundUseCase _stopUseCase;
  final SetAmbientVolumeUseCase _setVolumeUseCase;

  StreamSubscription<dynamic>? _externalSub;

  List<AmbientSound> _presets = const [];
  String _activeSoundId = 'off';
  bool _isPlaying = false;
  double _volume = 0.45;
  String? _errorMessage;

  List<AmbientSound> get presets => _presets;
  String get activeSoundId => _activeSoundId;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  String? get errorMessage => _errorMessage;

  AmbientSound? get activeSound {
    if (_activeSoundId == 'off') return null;
    try {
      return _presets.firstWhere((p) => p.id == _activeSoundId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _init(Stream<dynamic>? externalStateStream) async {
    final result = await _getPresetsUseCase();
    if (result is Success<List<AmbientSound>>) {
      _presets = result.data;
      notifyListeners();
    }

    if (externalStateStream != null) {
      _externalSub = externalStateStream.listen((state) {
        if (state != null) {
          _activeSoundId = state.soundId as String;
          _isPlaying = state.isPlaying as bool;
          _volume = state.volume as double;
          notifyListeners();
        }
      });
    }
  }

  Future<void> selectSound(String soundId) async {
    if (soundId == 'off') {
      await stop();
      return;
    }

    _activeSoundId = soundId;
    _isPlaying = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _playUseCase(soundId: soundId, volume: _volume);
    if (result is Error<void>) {
      _errorMessage = result.failure.message;
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_activeSoundId == 'off') {
      final first = _presets.isNotEmpty ? _presets.first.id : 'rain';
      await selectSound(first);
      return;
    }

    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
      final result = await _pauseUseCase();
      if (result is Error<void>) {
        _errorMessage = result.failure.message;
        notifyListeners();
      }
    } else {
      _isPlaying = true;
      notifyListeners();
      final result = await _playUseCase(
        soundId: _activeSoundId,
        volume: _volume,
      );
      if (result is Error<void>) {
        _errorMessage = result.failure.message;
        _isPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    _volume = clamped;
    notifyListeners();

    final result = await _setVolumeUseCase(clamped);
    if (result is Error<void>) {
      _errorMessage = result.failure.message;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _activeSoundId = 'off';
    _isPlaying = false;
    notifyListeners();

    final result = await _stopUseCase();
    if (result is Error<void>) {
      _errorMessage = result.failure.message;
      notifyListeners();
    }
  }

  Future<void> nextPreset() async {
    if (_presets.isEmpty) return;
    final currentIndex = _presets.indexWhere((p) => p.id == _activeSoundId);
    final nextIndex = (currentIndex + 1) % _presets.length;
    await selectSound(_presets[nextIndex].id);
  }

  Future<void> previousPreset() async {
    if (_presets.isEmpty) return;
    final currentIndex = _presets.indexWhere((p) => p.id == _activeSoundId);
    final prevIndex = currentIndex <= 0
        ? _presets.length - 1
        : currentIndex - 1;
    await selectSound(_presets[prevIndex].id);
  }

  @override
  void dispose() {
    _externalSub?.cancel();
    super.dispose();
  }
}
