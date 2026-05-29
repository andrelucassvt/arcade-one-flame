import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/cubit/cubit.dart';
import 'package:arcade_one/gen/assets.gen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioCache extends Mock implements AudioCache {}

class _MockAudioPool extends Mock implements AudioPool {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _MockStorageService extends Mock implements StorageService {}

class _FakeAssetSource extends Fake implements AssetSource {}

void main() {
  group('AudioCubit', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late AudioCache audioCache;
    late AudioPool thrustTapPool;
    late AudioPlayer enginePlayer;
    late AudioPlayer deathPlayer;
    late StorageService storage;

    setUpAll(() {
      registerFallbackValue(_FakeAssetSource());
      registerFallbackValue(ReleaseMode.stop);
    });

    setUp(() {
      audioCache = _MockAudioCache();
      thrustTapPool = _MockAudioPool();
      enginePlayer = _MockAudioPlayer();
      deathPlayer = _MockAudioPlayer();
      storage = _MockStorageService();

      when(() => enginePlayer.audioCache).thenReturn(audioCache);
      when(() => deathPlayer.audioCache).thenReturn(audioCache);

      when(enginePlayer.dispose).thenAnswer((_) async {});
      when(deathPlayer.dispose).thenAnswer((_) async {});
      when(thrustTapPool.dispose).thenAnswer((_) async {});
      when(
        () => thrustTapPool.start(volume: any(named: 'volume')),
      ).thenAnswer((_) async => () async {});

      when(() => enginePlayer.setVolume(any())).thenAnswer((_) async {});
      when(() => deathPlayer.setVolume(any())).thenAnswer((_) async {});
      when(
        () => enginePlayer.play(any(), volume: any(named: 'volume')),
      ).thenAnswer((_) async {});
      when(() => enginePlayer.setReleaseMode(any())).thenAnswer((_) async {});
      when(enginePlayer.stop).thenAnswer((_) async {});

      when(() => storage.getDouble(any())).thenAnswer((_) async => null);
      when(() => storage.setDouble(any(), any())).thenAnswer((_) async {});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers'),
            (_) => null,
          );
    });

    test(
      'can be instantiated',
      () => expect(
        AudioCubit(enginePlayer: enginePlayer, deathPlayer: deathPlayer),
        isA<AudioCubit>(),
      ),
    );

    // ── Testes de persistência ────────────────────────────────────────────

    blocTest<AudioCubit, AudioState>(
      'init emite AudioState(volume: 0) quando storage retorna 0.0',
      setUp: () {
        when(
          () => storage.getDouble('audio_volume'),
        ).thenAnswer((_) async => 0.0);
      },
      build: () => AudioCubit(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
      ),
      act: (cubit) => cubit.init(),
      expect: () => [const AudioState(volume: 0)],
      verify: (_) {
        verify(() => enginePlayer.setVolume(any(that: equals(0)))).called(1);
        verify(() => deathPlayer.setVolume(any(that: equals(0)))).called(1);
      },
    );

    blocTest<AudioCubit, AudioState>(
      'init não emite nada quando storage retorna null',
      build: () => AudioCubit(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
      ),
      act: (cubit) => cubit.init(),
      expect: () => <AudioState>[],
    );

    blocTest<AudioCubit, AudioState>(
      'toggleVolume salva volume 0 no storage ao mutar',
      build: () => AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
      ),
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState(volume: 0)],
      verify: (_) {
        verify(() => storage.setDouble('audio_volume', 0)).called(1);
      },
    );

    blocTest<AudioCubit, AudioState>(
      'toggleVolume salva volume 1 no storage ao desmutar',
      build: () => AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
        volume: 0,
      ),
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState()],
      verify: (_) {
        verify(() => storage.setDouble('audio_volume', 1)).called(1);
      },
    );

    // ── Testes existentes ─────────────────────────────────────────────────

    blocTest<AudioCubit, AudioState>(
      'toggleVolume mutes the volume when the volume is not 0',
      build: () => AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
      ),
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState(volume: 0)],
      verify: (_) {
        verify(() => enginePlayer.setVolume(any(that: equals(0)))).called(1);
        verify(() => deathPlayer.setVolume(any(that: equals(0)))).called(1);
      },
    );

    blocTest<AudioCubit, AudioState>(
      'toggleVolume unmutes the volume when the volume is 0',
      build: () => AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
        volume: 0,
      ),
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState()],
      verify: (_) {
        verify(
          () => enginePlayer.setVolume(
            any(that: equals(AudioCubit.engineVolumeFactor)),
          ),
        ).called(1);
        verify(() => deathPlayer.setVolume(any(that: equals(1)))).called(1);
      },
    );

    test('startEngineLoop fades in to the reduced engine volume', () async {
      final cubit = AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
      );

      await cubit.startEngineLoop();

      verify(() => enginePlayer.setReleaseMode(ReleaseMode.loop)).called(1);
      verify(
        () => enginePlayer.play(
          any(
            that: isA<AssetSource>().having(
              (source) => source.path,
              'path',
              Assets.audio.engineFire,
            ),
          ),
          volume: any(named: 'volume', that: equals(0)),
        ),
      ).called(1);
      verify(
        () => enginePlayer.setVolume(
          any(that: equals(AudioCubit.engineVolumeFactor)),
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    test('startEngineLoop does not start sound when muted', () async {
      final cubit = AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
        volume: 0,
      );

      await cubit.startEngineLoop();

      verifyNever(() => enginePlayer.setReleaseMode(any()));
      verifyNever(
        () => enginePlayer.play(any(), volume: any(named: 'volume')),
      );
    });

    test('stopEngineLoop fades out and stops the engine player', () async {
      final cubit = AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
      );

      await cubit.startEngineLoop();
      await cubit.stopEngineLoop();

      verify(enginePlayer.stop).called(1);
    });

    test('playThrustTap starts pooled sound with current volume', () async {
      final cubit = AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        thrustTapPool: Future.value(thrustTapPool),
        storage: storage,
      );

      await cubit.playThrustTap();

      verify(
        () => thrustTapPool.start(
          volume: any(named: 'volume', that: equals(1)),
        ),
      ).called(1);
    });

    test('playThrustTap does not start sound when muted', () async {
      final cubit = AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        thrustTapPool: Future.value(thrustTapPool),
        storage: storage,
        volume: 0,
      );

      await cubit.playThrustTap();

      verifyNever(() => thrustTapPool.start(volume: any(named: 'volume')));
    });

    test('close disposes every audio player', () async {
      final cubit = AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        storage: storage,
      );

      await cubit.close();

      verify(enginePlayer.dispose).called(1);
      verify(deathPlayer.dispose).called(1);
    });

    test('close disposes thrust tap pool when present', () async {
      final cubit = AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
        thrustTapPool: Future.value(thrustTapPool),
        storage: storage,
      );

      await cubit.close();

      verify(thrustTapPool.dispose).called(1);
    });
  });
}
