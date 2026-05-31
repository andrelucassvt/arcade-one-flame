import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/cubit/cubit.dart';
import 'package:arcade_one/game/game_audio_assets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioCache extends Mock implements AudioCache {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _MockStorageService extends Mock implements StorageService {}

class _FakeAssetSource extends Fake implements AssetSource {}

void main() {
  group('AudioCubit', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late AudioCache audioCache;
    late AudioPlayer deathPlayer;
    late AudioPlayer bgmPlayer;
    late StorageService storage;

    setUpAll(() {
      registerFallbackValue(_FakeAssetSource());
      registerFallbackValue(ReleaseMode.stop);
    });

    setUp(() {
      audioCache = _MockAudioCache();
      deathPlayer = _MockAudioPlayer();
      bgmPlayer = _MockAudioPlayer();
      storage = _MockStorageService();

      when(() => deathPlayer.audioCache).thenReturn(audioCache);

      when(deathPlayer.dispose).thenAnswer((_) async {});
      when(bgmPlayer.dispose).thenAnswer((_) async {});

      when(() => deathPlayer.setVolume(any())).thenAnswer((_) async {});
      when(() => bgmPlayer.setVolume(any())).thenAnswer((_) async {});
      when(
        () => bgmPlayer.play(any(), volume: any(named: 'volume')),
      ).thenAnswer((_) async {});
      when(() => bgmPlayer.setReleaseMode(any())).thenAnswer((_) async {});
      when(bgmPlayer.stop).thenAnswer((_) async {});

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
        AudioCubit(
          deathPlayer: deathPlayer,
          bgmPlayer: bgmPlayer,
        ),
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
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
        storage: storage,
      ),
      act: (cubit) => cubit.init(),
      expect: () => [const AudioState(volume: 0)],
      verify: (_) {
        verify(() => deathPlayer.setVolume(any(that: equals(0)))).called(1);
        verify(() => bgmPlayer.setVolume(any(that: equals(0)))).called(1);
      },
    );

    blocTest<AudioCubit, AudioState>(
      'init não emite nada quando storage retorna null',
      build: () => AudioCubit(
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
        storage: storage,
      ),
      act: (cubit) => cubit.init(),
      expect: () => <AudioState>[],
    );

    blocTest<AudioCubit, AudioState>(
      'toggleVolume salva volume 0 no storage ao mutar',
      build: () => AudioCubit.test(
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
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
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
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
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
        storage: storage,
      ),
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState(volume: 0)],
      verify: (_) {
        verify(() => deathPlayer.setVolume(any(that: equals(0)))).called(1);
        verify(() => bgmPlayer.setVolume(any(that: equals(0)))).called(1);
      },
    );

    blocTest<AudioCubit, AudioState>(
      'toggleVolume unmutes the volume when the volume is 0',
      build: () => AudioCubit.test(
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
        storage: storage,
        volume: 0,
      ),
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState()],
      verify: (_) {
        verify(() => deathPlayer.setVolume(any(that: equals(1)))).called(1);
        verify(() => bgmPlayer.setVolume(any(that: equals(1)))).called(1);
      },
    );

    // ── Testes de BGM ─────────────────────────────────────────────────────

    test('startBgm plays BGM in loop with current volume', () async {
      final cubit = AudioCubit.test(
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
        storage: storage,
      );

      await cubit.startBgm();

      verify(() => bgmPlayer.setReleaseMode(ReleaseMode.loop)).called(1);
      verify(
        () => bgmPlayer.play(
          any(
            that: isA<AssetSource>().having(
              (source) => source.path,
              'path',
              bgmAudioAsset,
            ),
          ),
          volume: any(named: 'volume', that: equals(1.0)),
        ),
      ).called(1);
    });

    test('startBgm does not start when muted', () async {
      final cubit = AudioCubit.test(
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
        storage: storage,
        volume: 0,
      );

      await cubit.startBgm();

      verifyNever(() => bgmPlayer.setReleaseMode(any()));
      verifyNever(() => bgmPlayer.play(any(), volume: any(named: 'volume')));
    });

    test('stopBgm stops the bgm player', () async {
      final cubit = AudioCubit.test(
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
        storage: storage,
      );

      await cubit.startBgm();
      await cubit.stopBgm();

      verify(bgmPlayer.stop).called(1);
    });

    test('close disposes every audio player', () async {
      final cubit = AudioCubit.test(
        deathPlayer: deathPlayer,
        bgmPlayer: bgmPlayer,
        storage: storage,
      );

      await cubit.close();

      verify(deathPlayer.dispose).called(1);
      verify(bgmPlayer.dispose).called(1);
    });
  });
}
