import 'package:arcade_one/game/game_image_assets.dart';
import 'package:arcade_one/game/player_ship/player_ship_skin.dart';
import 'package:arcade_one/l10n/l10n.dart';

const PlayerShipSkin defaultPlayerShipSkin = PlayerShipSkin(
  id: 'default',
  assetPath: playerShipImageAsset,
  unlockKm: 0,
);

const List<PlayerShipSkin> playerShipSkins = [
  defaultPlayerShipSkin,
  PlayerShipSkin(
    id: 'mars',
    assetPath: playerShipMarsImageAsset,
    unlockKm: 250,
  ),
  PlayerShipSkin(
    id: 'asteroid_belt',
    assetPath: playerShipAsteroidBeltImageAsset,
    unlockKm: 600,
  ),
  PlayerShipSkin(
    id: 'jupiter',
    assetPath: playerShipJupiterImageAsset,
    unlockKm: 1000,
  ),
  PlayerShipSkin(
    id: 'saturn',
    assetPath: playerShipSaturnImageAsset,
    unlockKm: 1500,
  ),
  PlayerShipSkin(
    id: 'ice_giants',
    assetPath: playerShipIceGiantsImageAsset,
    unlockKm: 2100,
  ),
  PlayerShipSkin(
    id: 'kuiper_belt',
    assetPath: playerShipKuiperBeltImageAsset,
    unlockKm: 2800,
  ),
  PlayerShipSkin(
    id: 'orion_nebula',
    assetPath: playerShipOrionNebulaImageAsset,
    unlockKm: 3600,
  ),
  PlayerShipSkin(
    id: 'pillars_creation',
    assetPath: playerShipPillarsCreationImageAsset,
    unlockKm: 4500,
  ),
  PlayerShipSkin(
    id: 'black_hole',
    assetPath: playerShipBlackHoleImageAsset,
    unlockKm: 5600,
  ),
  PlayerShipSkin(
    id: 'andromeda',
    assetPath: playerShipAndromedaImageAsset,
    unlockKm: 7000,
  ),
  PlayerShipSkin(
    id: 'deep_quasar',
    assetPath: playerShipDeepQuasarImageAsset,
    unlockKm: 8500,
  ),
];

PlayerShipSkin playerShipSkinById(String id) {
  for (final ship in playerShipSkins) {
    if (ship.id == id) {
      return ship;
    }
  }

  return defaultPlayerShipSkin;
}

List<PlayerShipSkin> unlockedPlayerShipSkins(double bestDistanceKm) {
  return playerShipSkins
      .where((ship) => isPlayerShipUnlocked(ship, bestDistanceKm))
      .toList(growable: false);
}

bool isPlayerShipUnlocked(PlayerShipSkin ship, double bestDistanceKm) {
  return ship.unlockKm <= bestDistanceKm;
}

String localizedPlayerShipName(
  AppLocalizations l10n,
  PlayerShipSkin ship,
) {
  return switch (ship.id) {
    'mars' => l10n.titleShipMarsName,
    'asteroid_belt' => l10n.titleShipAsteroidBeltName,
    'jupiter' => l10n.titleShipJupiterName,
    'saturn' => l10n.titleShipSaturnName,
    'ice_giants' => l10n.titleShipIceGiantsName,
    'kuiper_belt' => l10n.titleShipKuiperBeltName,
    'orion_nebula' => l10n.titleShipOrionNebulaName,
    'pillars_creation' => l10n.titleShipPillarsCreationName,
    'black_hole' => l10n.titleShipBlackHoleName,
    'andromeda' => l10n.titleShipAndromedaName,
    'deep_quasar' => l10n.titleShipDeepQuasarName,
    _ => l10n.titleShipDefaultName,
  };
}
