import 'package:arcade_one/l10n/l10n.dart';
import 'package:flutter/material.dart';

class GameOverPopup extends StatelessWidget {
  const GameOverPopup({
    required this.onRestart,
    super.key,
  });

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xEE0B1024),
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 44,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.gameOverTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.gameOverMessage,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRestart,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(l10n.restartButtonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
