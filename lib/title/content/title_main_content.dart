import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/title/content/title_control_mode_selector.dart';
import 'package:arcade_one/title/content/title_hero.dart';
import 'package:arcade_one/title/content/title_start_button.dart';
import 'package:flutter/material.dart';

class TitleMainContent extends StatelessWidget {
  const TitleMainContent({
    required this.selectedControlMode,
    required this.onControlModeChanged,
    super.key,
  });

  final GameControlMode selectedControlMode;
  final ValueChanged<GameControlMode> onControlModeChanged;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Column(
      children: [
        TitleHero(isWide: isWide),
        const SizedBox(height: 28),
        TitleControlModeSelector(
          selectedMode: selectedControlMode,
          onChanged: onControlModeChanged,
        ),
        const SizedBox(height: 24),
        TitleStartButton(controlMode: selectedControlMode),
      ],
    );
  }
}
