import 'dart:async';

import 'package:arcade_one/common/services/ads/ad_config.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/common/widgets/ad_banner_widget.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/loading/cubit/cubit.dart';
import 'package:arcade_one/title/title.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const double _bannerReservedHeight = 50;
const double _joystickBottomSpacing = 16;

class GamePage extends StatelessWidget {
  const GamePage({
    this.controlMode = GameControlMode.touch,
    this.playerShip = defaultPlayerShipSkin,
    this.quickPlay = false,
    super.key,
  });

  final GameControlMode controlMode;
  final PlayerShipSkin playerShip;
  final bool quickPlay;

  static Route<void> route({
    GameControlMode controlMode = GameControlMode.touch,
    PlayerShipSkin playerShip = defaultPlayerShipSkin,
    bool quickPlay = false,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => GamePage(
        controlMode: controlMode,
        playerShip: playerShip,
        quickPlay: quickPlay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameView(
        controlMode: controlMode,
        playerShip: playerShip,
        quickPlay: quickPlay,
      ),
    );
  }
}

class GameView extends StatefulWidget {
  const GameView({
    this.controlMode = GameControlMode.touch,
    this.playerShip = defaultPlayerShipSkin,
    this.quickPlay = false,
    super.key,
    this.game,
  });

  final GameControlMode controlMode;
  final PlayerShipSkin playerShip;
  final bool quickPlay;
  final FlameGame? game;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  FlameGame? _game;
  AudioCubit? _audioCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_audioCubit == null) {
      _audioCubit = context.read<AudioCubit>();
      unawaited(_audioCubit!.startBgm());
    }
  }

  @override
  void dispose() {
    unawaited(_audioCubit?.stopBgm());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall!.copyWith(color: Colors.white, fontSize: 4);
    final l10n = context.l10n;

    final audioCubit = context.read<AudioCubit>();
    _game ??=
        widget.game ??
        ArcadeOne(
          l10n: context.l10n,
          deathPlayer: audioCubit.deathPlayer,
          textStyle: textStyle,
          images: context.read<PreloadCubit>().images,
          storage: context.read<StorageService>(),
          controlMode: widget.controlMode,
          playerShip: widget.playerShip,
          waitingToStart: widget.quickPlay,
        );
    final game = _game!;
    if (game is ArcadeOne) {
      game.updateSafeAreaPadding(MediaQuery.paddingOf(context));
    }
    final bannerAdUnitId = AdConfig.maybeBanner;
    final joystickBottomPadding = bannerAdUnitId == null
        ? _joystickBottomSpacing
        : _bannerReservedHeight + _joystickBottomSpacing;

    return Stack(
      children: [
        Positioned.fill(
          child: GameWidget(
            game: game,
            overlayBuilderMap: {
              gameOverOverlayKey: (context, game) {
                final arcadeOne = game is ArcadeOne ? game : null;

                return GameOverPopup(
                  distanceKm: arcadeOne?.distanceKm.floor() ?? 0,
                  bestDistanceKm: arcadeOne?.bestDistanceKm.floor() ?? 0,
                  maxCombo: arcadeOne?.maxCombo ?? 0,
                  isNewRecord: arcadeOne?.isNewRecord ?? false,
                  playerShip: widget.playerShip,
                  onRestart: () {
                    if (game is ArcadeOne) {
                      unawaited(game.restartRun());
                    }
                  },
                  onReturnToTitle: () {
                    unawaited(
                      Navigator.of(context).pushReplacement<void, void>(
                        TitleView.route(),
                      ),
                    );
                  },
                );
              },
            },
          ),
        ),
        if (game is ArcadeOne && game.isWaitingToStart)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                game.startRun();
                setState(() {});
              },
              child: ColoredBox(
                color: const Color(0xCC080A19),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.quickPlayTapToStart,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.quickPlayHint,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (game is ArcadeOne && game.controlMode == GameControlMode.joystick)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: joystickBottomPadding),
                child: GameJoystick(
                  onDirectionChanged: game.setJoystickDirection,
                  onReleased: game.clearJoystick,
                ),
              ),
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
        if (bannerAdUnitId != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: AdBannerWidget(
                  adUnitId: bannerAdUnitId,
                  fallbackAdUnitId: AdConfig.maybeFallbackBanner,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
