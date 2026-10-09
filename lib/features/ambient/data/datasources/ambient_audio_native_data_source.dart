import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:todo/features/ambient/data/models/ambient_sound_model.dart';
import 'package:todo/features/ambient/domain/entities/ambient_playback_state.dart';

class AmbientAudioNativeException implements Exception {
  const AmbientAudioNativeException(this.message);
  final String message;

  @override
  String toString() => 'AmbientAudioNativeException: $message';
}

/// Native bridge datasource connecting to iOS AVAudioEngine and Android AudioTrack.
class AmbientAudioNativeDataSource {
  AmbientAudioNativeDataSource({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('com.helltrilla.todoapp/notifications') {
    _initChannelHandler();
  }

  final MethodChannel _channel;
  final StreamController<AmbientPlaybackState> _stateController =
      StreamController<AmbientPlaybackState>.broadcast();

  String _currentSoundId = 'off';
  bool _isPlaying = false;
  double _currentVolume = 0.45;

  Stream<AmbientPlaybackState> get stateStream => _stateController.stream;

  static const List<AmbientSoundModel> builtInPresets = [
    AmbientSoundModel(
      id: 'rain',
      title: '🌧 Дождь',
      description: 'Мягкий шум дождя и капли по стеклу',
      iconKey: 'water_drop',
    ),
    AmbientSoundModel(
      id: 'fire',
      title: '🔥 Костер',
      description: 'Уютный треск поленьев и теплое пламя',
      iconKey: 'local_fire_department',
    ),
    AmbientSoundModel(
      id: 'noise',
      title: '💨 Белый шум',
      description: 'Широкополосная маскировка шума для фокуса',
      iconKey: 'air',
    ),
    AmbientSoundModel(
      id: 'waves',
      title: '🌊 Прибой',
      description: 'Ритмичные волны морского побережья',
      iconKey: 'waves',
    ),
    AmbientSoundModel(
      id: 'cafe',
      title: '☕️ Кафе',
      description: 'Теплая атмосфера кофейни и легкий лаунж',
      iconKey: 'local_cafe',
    ),
    AmbientSoundModel(
      id: 'vinyl',
      title: '💿 Винил',
      description: 'Аналоговый треск виниловой пластинки 33 RPM',
      iconKey: 'album',
    ),
  ];

  void _initChannelHandler() {
    if (kIsWeb) return;
    // We register or listen to ambient updates from Lock Screen / remote commands
    // Handled safely without overriding other handlers if already bound
  }

  void notifyExternalStateChange({
    required String soundId,
    required bool isPlaying,
    required double volume,
  }) {
    _currentSoundId = soundId;
    _isPlaying = isPlaying;
    _currentVolume = volume;
    _stateController.add(
      AmbientPlaybackState(
        soundId: _currentSoundId,
        isPlaying: _isPlaying,
        volume: _currentVolume,
      ),
    );
  }

  Future<List<AmbientSoundModel>> getPresets() async {
    return builtInPresets;
  }

  Future<void> play({required String soundId, double? volume}) async {
    final vol = (volume ?? _currentVolume).clamp(0.0, 1.0);
    _currentSoundId = soundId;
    _currentVolume = vol;
    _isPlaying = soundId != 'off';

    if (kIsWeb) {
      _emitCurrentState();
      return;
    }

    try {
      await _channel.invokeMethod<void>('setAmbientSound', <String, dynamic>{
        'sound': soundId,
        'volume': vol,
      });
      _emitCurrentState();
    } on PlatformException catch (e) {
      throw AmbientAudioNativeException(
        e.message ?? 'Ошибка воспроизведения звука',
      );
    } catch (e) {
      throw AmbientAudioNativeException('Не удалось запустить звук: $e');
    }
  }

  Future<void> pause() async {
    _isPlaying = false;

    if (kIsWeb) {
      _emitCurrentState();
      return;
    }

    try {
      await _channel.invokeMethod<void>('pauseAmbientSound');
      _emitCurrentState();
    } on PlatformException catch (e) {
      throw AmbientAudioNativeException(
        e.message ?? 'Ошибка приостановки звука',
      );
    } catch (e) {
      // Fallback to setting off
      try {
        await _channel.invokeMethod<void>('setAmbientSound', <String, dynamic>{
          'sound': 'off',
          'volume': _currentVolume,
        });
      } catch (_) {}
      _emitCurrentState();
    }
  }

  Future<void> stop() async {
    _currentSoundId = 'off';
    _isPlaying = false;

    if (kIsWeb) {
      _emitCurrentState();
      return;
    }

    try {
      await _channel.invokeMethod<void>('setAmbientSound', <String, dynamic>{
        'sound': 'off',
        'volume': _currentVolume,
      });
      _emitCurrentState();
    } on PlatformException catch (e) {
      throw AmbientAudioNativeException(
        e.message ?? 'Ошибка остановки воспроизведения',
      );
    } catch (e) {
      throw AmbientAudioNativeException('Не удалось остановить звук: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);

    if (kIsWeb) {
      _emitCurrentState();
      return;
    }

    if (_isPlaying && _currentSoundId != 'off') {
      try {
        await _channel.invokeMethod<void>('setAmbientSound', <String, dynamic>{
          'sound': _currentSoundId,
          'volume': _currentVolume,
        });
        _emitCurrentState();
      } on PlatformException catch (e) {
        throw AmbientAudioNativeException(
          e.message ?? 'Ошибка изменения громкости',
        );
      } catch (e) {
        throw AmbientAudioNativeException('Не удалось изменить громкость: $e');
      }
    } else {
      _emitCurrentState();
    }
  }

  Future<AmbientPlaybackState> getCurrentState() async {
    if (kIsWeb) {
      return AmbientPlaybackState(
        soundId: _currentSoundId,
        isPlaying: _isPlaying,
        volume: _currentVolume,
      );
    }

    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'getAmbientSoundState',
      );
      if (map != null) {
        _currentSoundId = (map['sound'] as String?) ?? _currentSoundId;
        _isPlaying = (map['isPlaying'] as bool?) ?? _isPlaying;
        _currentVolume = (map['volume'] as num?)?.toDouble() ?? _currentVolume;
      }
    } catch (_) {}

    return AmbientPlaybackState(
      soundId: _currentSoundId,
      isPlaying: _isPlaying,
      volume: _currentVolume,
    );
  }

  void _emitCurrentState() {
    _stateController.add(
      AmbientPlaybackState(
        soundId: _currentSoundId,
        isPlaying: _isPlaying,
        volume: _currentVolume,
      ),
    );
  }

  void dispose() {
    _stateController.close();
  }
}
