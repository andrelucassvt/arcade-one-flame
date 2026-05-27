import 'dart:ui';

import 'package:arcade_one/game/game_audio_assets.dart';
import 'package:arcade_one/game/game_image_assets.dart';
import 'package:arcade_one/gen/assets.gen.dart';
import 'package:arcade_one/loading/loading.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flame/cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockImages extends Mock implements Images {}

class _MockAudioCache extends Mock implements AudioCache {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(PreloadCubit, () {
    group('loadSequentially', () {
      late Images images;
      late AudioCache audio;

      blocTest<PreloadCubit, PreloadState>(
        'loads assets',
        setUp: () {
          images = _MockImages();
          when(
            () => images.loadAll([
              Assets.images.unicornAnimation.path,
              ...gameImageAssets,
            ]),
          ).thenAnswer((invocation) => Future.value(<Image>[]));

          audio = _MockAudioCache();
          when(
            () => audio.loadAll([
              thrustTapAudioAsset,
              Assets.audio.engineFire,
              Assets.audio.death,
            ]),
          ).thenAnswer(
            (invocation) async => [
              Uri.parse(thrustTapAudioAsset),
              Uri.parse(Assets.audio.engineFire),
              Uri.parse(Assets.audio.death),
            ],
          );
        },
        build: () => PreloadCubit(images, audio),
        act: (bloc) => bloc.loadSequentially(),
        expect: () => [
          isA<PreloadState>()
              .having((s) => s.currentLabel, 'currentLabel', equals(''))
              .having((s) => s.totalCount, 'totalCount', equals(2)),
          isA<PreloadState>()
              .having((s) => s.currentLabel, 'currentLabel', equals('audio'))
              .having((s) => s.isComplete, 'isComplete', isFalse)
              .having((s) => s.loadedCount, 'loadedCount', equals(0)),
          isA<PreloadState>()
              .having((s) => s.currentLabel, 'currentLabel', equals('audio'))
              .having((s) => s.isComplete, 'isComplete', isFalse)
              .having((s) => s.loadedCount, 'loadedCount', equals(1)),
          isA<PreloadState>()
              .having((s) => s.currentLabel, 'currentLabel', equals('images'))
              .having((s) => s.isComplete, 'isComplete', isFalse)
              .having((s) => s.loadedCount, 'loadedCount', equals(1)),
          isA<PreloadState>()
              .having((s) => s.currentLabel, 'currentLabel', equals('images'))
              .having((s) => s.isComplete, 'isComplete', isTrue)
              .having((s) => s.loadedCount, 'loadedCount', equals(2)),
        ],
        verify: (bloc) {
          verify(
            () => audio.loadAll([
              thrustTapAudioAsset,
              Assets.audio.engineFire,
              Assets.audio.death,
            ]),
          ).called(1);
          verify(
            () => images.loadAll([
              Assets.images.unicornAnimation.path,
              ...gameImageAssets,
            ]),
          ).called(1);
        },
      );
    });
  });
}
