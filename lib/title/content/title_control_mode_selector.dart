import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:flutter/material.dart';

class TitleControlModeSelector extends StatelessWidget {
  const TitleControlModeSelector({
    required this.selectedMode,
    required this.onChanged,
    super.key,
  });

  final GameControlMode selectedMode;
  final ValueChanged<GameControlMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.titleControlModeLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xCCFFFFFF),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<GameControlMode>(
          segments: [
            ButtonSegment<GameControlMode>(
              value: GameControlMode.touch,
              icon: const Icon(Icons.touch_app_rounded),
              label: Text(l10n.titleControlModeTouch),
            ),
            ButtonSegment<GameControlMode>(
              value: GameControlMode.joystick,
              icon: const Icon(Icons.gamepad_rounded),
              label: Text(l10n.titleControlModeJoystick),
            ),
          ],
          selected: {selectedMode},
          onSelectionChanged: (selected) => onChanged(selected.single),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFFFC857);
              }
              return const Color(0x33111827);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF111827);
              }
              return Colors.white;
            }),
            side: WidgetStateProperty.all(
              const BorderSide(color: Color(0x8857E4FF)),
            ),
            textStyle: WidgetStateProperty.all(textStyle),
          ),
        ),
      ],
    );
  }
}
