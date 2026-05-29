import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/title/content/title_control_mode_selector.dart';
import 'package:arcade_one/title/content/title_hero.dart';
import 'package:arcade_one/title/content/title_ship_selector_button.dart';
import 'package:arcade_one/title/content/title_start_button.dart';
import 'package:flutter/material.dart';

class TitleMainContent extends StatelessWidget {
  const TitleMainContent({
    required this.selectedControlMode,
    required this.selectedShip,
    required this.bestDistanceKm,
    required this.onShipSelectorPressed,
    required this.onControlModeChanged,
    super.key,
  });

  final GameControlMode selectedControlMode;
  final PlayerShipSkin selectedShip;
  final double bestDistanceKm;
  final VoidCallback onShipSelectorPressed;
  final ValueChanged<GameControlMode> onControlModeChanged;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Column(
      children: [
        TitleHero(isWide: isWide, selectedShip: selectedShip),
        const SizedBox(height: 18),
        TitleShipSelectorButton(
          selectedShip: selectedShip,
          onPressed: onShipSelectorPressed,
        ),
        const SizedBox(height: 24),
        TitleControlModeSelector(
          selectedMode: selectedControlMode,
          onChanged: onControlModeChanged,
        ),
        const SizedBox(height: 24),
        TitleStartButton(
          controlMode: selectedControlMode,
          playerShip: selectedShip,
        ),
      ],
    );
  }
}
