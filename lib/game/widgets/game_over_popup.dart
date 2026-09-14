import 'dart:typed_data';

import 'package:arcade_one/common/services/share/share_service.dart';
import 'package:arcade_one/game/player_ship/player_ship.dart';
import 'package:arcade_one/game/widgets/run_share_card.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameOverPopup extends StatefulWidget {
  const GameOverPopup({
    required this.distanceKm,
    required this.onRestart,
    required this.onReturnToTitle,
    this.bestDistanceKm = 0,
    this.maxCombo = 0,
    this.isNewRecord = false,
    this.playerShip = defaultPlayerShipSkin,
    this.captureCard,
    super.key,
  });

  final int distanceKm;
  final int bestDistanceKm;
  final int maxCombo;
  final bool isNewRecord;
  final PlayerShipSkin playerShip;
  final Future<Uint8List?> Function()? captureCard;
  final VoidCallback onRestart;
  final VoidCallback onReturnToTitle;

  @override
  State<GameOverPopup> createState() => _GameOverPopupState();
}

class _GameOverPopupState extends State<GameOverPopup> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareRun() async {
    if (_isSharing) {
      return;
    }

    final shareService = context.read<ShareService>();
    final message = context.l10n.shareRunText(widget.distanceKm);
    final capture = widget.captureCard ?? () => captureRunShareCard(_cardKey);
    setState(() => _isSharing = true);

    try {
      final cardPng = await capture();
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await shareService.shareRunResult(
        RunShareResult(
          message: message,
          cardPng: cardPng,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object catch (error) {
      debugPrint('Share run failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: _cardKey,
                  child: RunShareCard(
                    distanceKm: widget.distanceKm,
                    bestDistanceKm: widget.bestDistanceKm,
                    maxCombo: widget.maxCombo,
                    isNewRecord: widget.isNewRecord,
                    playerShip: widget.playerShip,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.gameOverMessage,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSharing ? null : _shareRun,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: Text(l10n.shareButtonLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC857),
                      foregroundColor: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onRestart,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(l10n.restartButtonLabel),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onReturnToTitle,
                    icon: const Icon(Icons.home_rounded),
                    label: Text(l10n.returnToTitleButtonLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
