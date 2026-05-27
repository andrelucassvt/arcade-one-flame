import 'dart:async';

import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/loading/cubit/cubit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const GamePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final audioCache = context.read<PreloadCubit>().audio;
        return AudioCubit(
          enginePlayer: AudioPlayer()..audioCache = audioCache,
          deathPlayer: AudioPlayer()..audioCache = audioCache,
        );
      },
      child: const Scaffold(body: GameView()),
    );
  }
}

class GameView extends StatefulWidget {
  const GameView({super.key, this.game});

  final FlameGame? game;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  FlameGame? _game;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall!.copyWith(color: Colors.white, fontSize: 4);

    _game ??=
        widget.game ??
        ArcadeOne(
          l10n: context.l10n,
          enginePlayer: context.read<AudioCubit>().enginePlayer,
          deathPlayer: context.read<AudioCubit>().deathPlayer,
          textStyle: textStyle,
          images: context.read<PreloadCubit>().images,
        );
    final game = _game!;
    if (game is ArcadeOne) {
      game.updateSafeAreaPadding(MediaQuery.paddingOf(context));
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GameWidget(
            game: game,
            overlayBuilderMap: {
              gameOverOverlayKey: (context, game) {
                return GameOverPopup(
                  onRestart: () {
                    if (game is ArcadeOne) {
                      unawaited(game.restartRun());
                    }
                  },
                );
              },
            },
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: BlocBuilder<AudioCubit, AudioState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    state.volume == 0 ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: () => context.read<AudioCubit>().toggleVolume(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
