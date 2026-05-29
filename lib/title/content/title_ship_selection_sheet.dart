import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:flutter/material.dart';

class TitleShipSelectionSheet extends StatelessWidget {
  const TitleShipSelectionSheet({
    required this.selectedShip,
    required this.bestDistanceKm,
    required this.onShipSelected,
    super.key,
  });

  final PlayerShipSkin selectedShip;
  final double bestDistanceKm;
  final ValueChanged<PlayerShipSkin> onShipSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenHeight * 0.68).clamp(320.0, 560.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.titleShipSelectionTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).closeButtonTooltip,
                  color: const Color(0xFFEAF7FF),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: sheetHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
                  return GridView.builder(
                    itemCount: playerShipSkins.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.84,
                    ),
                    itemBuilder: (context, index) {
                      final ship = playerShipSkins[index];
                      return _ShipSelectionTile(
                        ship: ship,
                        selected: selectedShip == ship,
                        unlocked: isPlayerShipUnlocked(
                          ship,
                          bestDistanceKm,
                        ),
                        onSelected: () {
                          onShipSelected(ship);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipSelectionTile extends StatelessWidget {
  const _ShipSelectionTile({
    required this.ship,
    required this.selected,
    required this.unlocked,
    required this.onSelected,
  });

  final PlayerShipSkin ship;
  final bool selected;
  final bool unlocked;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shipName = localizedPlayerShipName(l10n, ship);
    final status = switch ((selected, unlocked)) {
      (true, _) => l10n.titleShipStatusSelected,
      (false, true) => l10n.titleShipStatusUnlocked,
      (false, false) => l10n.titleShipStatusLocked,
    };

    return Material(
      color: selected ? const Color(0x3357E4FF) : const Color(0x22101835),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: unlocked ? onSelected : null,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFF57E4FF)
                  : const Color(0x4457E4FF),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : unlocked
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.lock_rounded,
                    color: selected
                        ? const Color(0xFF57E4FF)
                        : const Color(0xBFFFFFFF),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Opacity(
                    opacity: unlocked ? 1 : 0.42,
                    child: Image.asset(
                      ship.assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shipName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: unlocked
                        ? const Color(0xFFDCE9FF)
                        : const Color(0xCCFFFFFF),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 3),
                  Text(
                    l10n.titleShipUnlockRequirement(ship.unlockKm.round()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xBFFFFFFF),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
