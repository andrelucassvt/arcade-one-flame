import 'package:arcade_one/game/cubit/cubit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioCache extends Mock implements AudioCache {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  group('AudioCubit', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late AudioCache audioCache;
    late AudioPlayer enginePlayer;
    late AudioPlayer deathPlayer;

    setUp(() {
      audioCache = _MockAudioCache();
      enginePlayer = _MockAudioPlayer();
      deathPlayer = _MockAudioPlayer();
      when(() => enginePlayer.audioCache).thenReturn(audioCache);
      when(() => deathPlayer.audioCache).thenReturn(audioCache);

      when(enginePlayer.dispose).thenAnswer((_) async {});
      when(deathPlayer.dispose).thenAnswer((_) async {});

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

    blocTest<AudioCubit, AudioState>(
      'toggleVolume mutes the volume when the volume is not 0',
      setUp: () {
        when(() => enginePlayer.setVolume(any())).thenAnswer((_) async {});
        when(() => deathPlayer.setVolume(any())).thenAnswer((_) async {});
      },
      build: () {
        return AudioCubit.test(
          enginePlayer: enginePlayer,
          deathPlayer: deathPlayer,
        );
      },
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState(volume: 0)],
      verify: (_) {
        verify(() => enginePlayer.setVolume(any(that: equals(0)))).called(1);
        verify(() => deathPlayer.setVolume(any(that: equals(0)))).called(1);
      },
    );

    blocTest<AudioCubit, AudioState>(
      'toggleVolume unmutes the volume when the volume is 0',
      setUp: () {
        when(() => enginePlayer.setVolume(any())).thenAnswer((_) async {});
        when(() => deathPlayer.setVolume(any())).thenAnswer((_) async {});
      },
      build: () {
        return AudioCubit.test(
          enginePlayer: enginePlayer,
          deathPlayer: deathPlayer,
          volume: 0,
        );
      },
      act: (cubit) => cubit.toggleVolume(),
      expect: () => [const AudioState()],
      verify: (_) {
        verify(() => enginePlayer.setVolume(any(that: equals(1)))).called(1);
        verify(() => deathPlayer.setVolume(any(that: equals(1)))).called(1);
      },
    );

    test('close disposes every audio player', () async {
      final cubit = AudioCubit.test(
        enginePlayer: enginePlayer,
        deathPlayer: deathPlayer,
      );

      await cubit.close();

      verify(enginePlayer.dispose).called(1);
      verify(deathPlayer.dispose).called(1);
    });
  });
}
