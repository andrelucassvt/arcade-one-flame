import 'dart:async';

import 'package:arcade_one/common/services/ads/ad_config.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/common/widgets/ad_banner_widget.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/loading/cubit/cubit.dart';
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
    return const Scaffold(body: GameView());
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

    final audioCubit = context.read<AudioCubit>();
    _game ??=
        widget.game ??
        ArcadeOne(
          l10n: context.l10n,
          enginePlayer: audioCubit.enginePlayer,
          deathPlayer: audioCubit.deathPlayer,
          playThrustTapSound: audioCubit.playThrustTap,
          textStyle: textStyle,
          images: context.read<PreloadCubit>().images,
          storage: context.read<StorageService>(),
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
                final distanceKm = switch (game) {
                  ArcadeOne(:final distanceKm) => distanceKm.floor(),
                  _ => 0,
                };

                return GameOverPopup(
                  distanceKm: distanceKm,
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
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AdBannerWidget(adUnitId: AdConfig.banner),
          ),
        ),
      ],
    );
  }
}
