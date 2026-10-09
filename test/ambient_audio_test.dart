import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/domain/entities/ambient_playback_state.dart';
import 'package:todo/features/ambient/domain/entities/ambient_sound.dart';
import 'package:todo/features/ambient/domain/repositories/i_ambient_audio_repository.dart';
import 'package:todo/features/ambient/domain/usecases/get_ambient_presets_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/pause_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/play_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/set_ambient_volume_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/stop_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/presentation/controllers/ambient_audio_controller.dart';

class FakeAmbientAudioRepo implements IAmbientAudioRepository {
  String currentSound = 'off';
  bool isPlaying = false;
  double volume = 0.45;
  final StreamController<AmbientPlaybackState> _stateController =
      StreamController<AmbientPlaybackState>.broadcast();

  final List<AmbientSound> mockPresets = const [
    AmbientSound(
      id: 'rain',
      title: '🌧 Дождь',
      description: 'Мягкий шум дождя',
      iconKey: 'water_drop',
    ),
    AmbientSound(
      id: 'fire',
      title: '🔥 Костер',
      description: 'Уютный треск костра',
      iconKey: 'local_fire_department',
    ),
    AmbientSound(
      id: 'noise',
      title: '💨 Белый шум',
      description: 'Широкополосная маскировка шума',
      iconKey: 'air',
    ),
  ];

  @override
  Stream<AmbientPlaybackState> get stateChanges => _stateController.stream;

  @override
  Future<Result<List<AmbientSound>>> getPresets() async {
    return Success(mockPresets);
  }

  @override
  Future<Result<AmbientPlaybackState>> getCurrentState() async {
    return Success(
      AmbientPlaybackState(
        soundId: currentSound,
        isPlaying: isPlaying,
        volume: volume,
      ),
    );
  }

  @override
  Future<Result<void>> play({required String soundId, double? volume}) async {
    currentSound = soundId;
    isPlaying = true;
    if (volume != null) this.volume = volume;
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> pause() async {
    isPlaying = false;
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> stop() async {
    currentSound = 'off';
    isPlaying = false;
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> setVolume(double vol) async {
    volume = vol;
    _emit();
    return const Success(null);
  }

  void _emit() {
    _stateController.add(
      AmbientPlaybackState(
        soundId: currentSound,
        isPlaying: isPlaying,
        volume: volume,
      ),
    );
  }

  void emitExternalState(AmbientPlaybackState state) {
    currentSound = state.soundId;
    isPlaying = state.isPlaying;
    volume = state.volume;
    _stateController.add(state);
  }
}

void main() {
  group('Feature 3: Ambient Audio & Background Soundscapes Tests', () {
    late FakeAmbientAudioRepo fakeRepo;

    setUp(() {
      fakeRepo = FakeAmbientAudioRepo();
    });

    test('GetAmbientPresetsUseCase returns all built-in soundscapes', () async {
      final useCase = GetAmbientPresetsUseCase(fakeRepo);
      final result = await useCase();

      expect(result, isA<Success<List<AmbientSound>>>());
      final list = (result as Success<List<AmbientSound>>).data;
      expect(list.length, 3);
      expect(list.map((e) => e.id), containsAll(['rain', 'fire', 'noise']));
    });

    test(
      'PlayAmbientSoundUseCase rejects empty soundId and invalid volume',
      () async {
        final useCase = PlayAmbientSoundUseCase(fakeRepo);

        final emptyResult = await useCase(soundId: '   ');
        expect(emptyResult, isA<Error<void>>());
        expect((emptyResult as Error<void>).failure, isA<ServerFailure>());

        final invalidVolResult = await useCase(soundId: 'rain', volume: 1.5);
        expect(invalidVolResult, isA<Error<void>>());

        final successResult = await useCase(soundId: 'rain', volume: 0.7);
        expect(successResult, isA<Success<void>>());
        expect(fakeRepo.currentSound, 'rain');
        expect(fakeRepo.isPlaying, isTrue);
        expect(fakeRepo.volume, 0.7);
      },
    );

    test(
      'SetAmbientVolumeUseCase clamps and validates volume boundaries',
      () async {
        final useCase = SetAmbientVolumeUseCase(fakeRepo);

        final negResult = await useCase(-0.1);
        expect(negResult, isA<Error<void>>());

        final overResult = await useCase(1.2);
        expect(overResult, isA<Error<void>>());

        final validResult = await useCase(0.85);
        expect(validResult, isA<Success<void>>());
        expect(fakeRepo.volume, 0.85);
      },
    );

    test(
      'PauseAmbientSoundUseCase and StopAmbientSoundUseCase update state',
      () async {
        final playUseCase = PlayAmbientSoundUseCase(fakeRepo);
        final pauseUseCase = PauseAmbientSoundUseCase(fakeRepo);
        final stopUseCase = StopAmbientSoundUseCase(fakeRepo);

        await playUseCase(soundId: 'fire');
        expect(fakeRepo.isPlaying, isTrue);

        await pauseUseCase();
        expect(fakeRepo.isPlaying, isFalse);
        expect(fakeRepo.currentSound, 'fire');

        await stopUseCase();
        expect(fakeRepo.isPlaying, isFalse);
        expect(fakeRepo.currentSound, 'off');
      },
    );

    test(
      'AmbientAudioController initializes presets and plays sound',
      () async {
        final controller = AmbientAudioController(
          getPresetsUseCase: GetAmbientPresetsUseCase(fakeRepo),
          playUseCase: PlayAmbientSoundUseCase(fakeRepo),
          pauseUseCase: PauseAmbientSoundUseCase(fakeRepo),
          stopUseCase: StopAmbientSoundUseCase(fakeRepo),
          setVolumeUseCase: SetAmbientVolumeUseCase(fakeRepo),
          externalStateStream: fakeRepo.stateChanges,
        );

        // Microtask to allow async init to finish
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(controller.presets.length, 3);
        expect(controller.activeSoundId, 'off');
        expect(controller.isPlaying, isFalse);

        // Select Fire preset
        await controller.selectSound('fire');
        expect(controller.activeSoundId, 'fire');
        expect(controller.isPlaying, isTrue);
        expect(controller.activeSound?.title, '🔥 Костер');

        // Toggle Play / Pause
        await controller.togglePlayPause();
        expect(controller.isPlaying, isFalse);
        expect(controller.activeSoundId, 'fire');

        await controller.togglePlayPause();
        expect(controller.isPlaying, isTrue);

        // Change Volume
        await controller.setVolume(0.8);
        expect(controller.volume, 0.8);

        // Next / Previous Preset Cycling
        await controller.nextPreset();
        expect(controller.activeSoundId, 'noise');

        await controller.previousPreset();
        expect(controller.activeSoundId, 'fire');

        // Stop
        await controller.stop();
        expect(controller.activeSoundId, 'off');
        expect(controller.isPlaying, isFalse);

        controller.dispose();
      },
    );

    test(
      'AmbientAudioController synchronizes with external Lock Screen events',
      () async {
        final controller = AmbientAudioController(
          getPresetsUseCase: GetAmbientPresetsUseCase(fakeRepo),
          playUseCase: PlayAmbientSoundUseCase(fakeRepo),
          pauseUseCase: PauseAmbientSoundUseCase(fakeRepo),
          stopUseCase: StopAmbientSoundUseCase(fakeRepo),
          setVolumeUseCase: SetAmbientVolumeUseCase(fakeRepo),
          externalStateStream: fakeRepo.stateChanges,
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Simulate lock screen next track action updating native state
        fakeRepo.emitExternalState(
          const AmbientPlaybackState(
            soundId: 'noise',
            isPlaying: true,
            volume: 0.9,
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(controller.activeSoundId, 'noise');
        expect(controller.isPlaying, isTrue);
        expect(controller.volume, 0.9);

        controller.dispose();
      },
    );
  });
}
