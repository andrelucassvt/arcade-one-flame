const String asteroidTileImageAsset = 'assets/images/asteroid_tile.png';
const String asteroidEarthMoonTileImageAsset =
    'assets/images/asteroids/asteroid_tile_earth_moon.png';
const String asteroidMarsTileImageAsset =
    'assets/images/asteroids/asteroid_tile_mars.png';
const String asteroidBeltTileImageAsset =
    'assets/images/asteroids/asteroid_tile_asteroid_belt.png';
const String asteroidJupiterTileImageAsset =
    'assets/images/asteroids/asteroid_tile_jupiter.png';
const String asteroidSaturnTileImageAsset =
    'assets/images/asteroids/asteroid_tile_saturn.png';
const String asteroidIceGiantsTileImageAsset =
    'assets/images/asteroids/asteroid_tile_ice_giants.png';
const String asteroidKuiperBeltTileImageAsset =
    'assets/images/asteroids/asteroid_tile_kuiper_belt.png';
const String asteroidOrionNebulaTileImageAsset =
    'assets/images/asteroids/asteroid_tile_orion_nebula.png';
const String asteroidPillarsCreationTileImageAsset =
    'assets/images/asteroids/asteroid_tile_pillars_creation.png';
const String asteroidBlackHoleTileImageAsset =
    'assets/images/asteroids/asteroid_tile_black_hole.png';
const String asteroidAndromedaTileImageAsset =
    'assets/images/asteroids/asteroid_tile_andromeda.png';
const String asteroidDeepQuasarTileImageAsset =
    'assets/images/asteroids/asteroid_tile_deep_quasar.png';
const String looseMeteorImageAsset = 'assets/images/loose_meteor.png';
const String playerShipImageAsset = 'assets/images/player_ship.png';
const String playerShipMarsImageAsset =
    'assets/images/ships/player_ship_mars.png';
const String playerShipAsteroidBeltImageAsset =
    'assets/images/ships/player_ship_asteroid_belt.png';
const String playerShipJupiterImageAsset =
    'assets/images/ships/player_ship_jupiter.png';
const String playerShipSaturnImageAsset =
    'assets/images/ships/player_ship_saturn.png';
const String playerShipIceGiantsImageAsset =
    'assets/images/ships/player_ship_ice_giants.png';
const String playerShipKuiperBeltImageAsset =
    'assets/images/ships/player_ship_kuiper_belt.png';
const String playerShipOrionNebulaImageAsset =
    'assets/images/ships/player_ship_orion_nebula.png';
const String playerShipPillarsCreationImageAsset =
    'assets/images/ships/player_ship_pillars_creation.png';
const String playerShipBlackHoleImageAsset =
    'assets/images/ships/player_ship_black_hole.png';
const String playerShipAndromedaImageAsset =
    'assets/images/ships/player_ship_andromeda.png';
const String playerShipDeepQuasarImageAsset =
    'assets/images/ships/player_ship_deep_quasar.png';
const String spaceEarthMoonBackgroundAsset =
    'assets/images/backgrounds/space_earth_moon.png';
const String spaceMarsBackgroundAsset =
    'assets/images/backgrounds/space_mars.png';
const String spaceAsteroidBeltBackgroundAsset =
    'assets/images/backgrounds/space_asteroid_belt.png';
const String spaceJupiterBackgroundAsset =
    'assets/images/backgrounds/space_jupiter.png';
const String spaceSaturnBackgroundAsset =
    'assets/images/backgrounds/space_saturn.png';
const String spaceIceGiantsBackgroundAsset =
    'assets/images/backgrounds/space_ice_giants.png';
const String spaceKuiperBeltBackgroundAsset =
    'assets/images/backgrounds/space_kuiper_belt.png';
const String spaceOrionNebulaBackgroundAsset =
    'assets/images/backgrounds/space_orion_nebula.png';
const String spacePillarsCreationBackgroundAsset =
    'assets/images/backgrounds/space_pillars_creation.png';
const String spaceBlackHoleBackgroundAsset =
    'assets/images/backgrounds/space_black_hole.png';
const String spaceAndromedaBackgroundAsset =
    'assets/images/backgrounds/space_andromeda.png';
const String spaceDeepQuasarBackgroundAsset =
    'assets/images/backgrounds/space_deep_quasar.png';

const Map<String, String> asteroidTileImageAssetsByLandmarkId = {
  'earth_moon': asteroidEarthMoonTileImageAsset,
  'mars': asteroidMarsTileImageAsset,
  'asteroid_belt': asteroidBeltTileImageAsset,
  'jupiter': asteroidJupiterTileImageAsset,
  'saturn': asteroidSaturnTileImageAsset,
  'ice_giants': asteroidIceGiantsTileImageAsset,
  'kuiper_belt': asteroidKuiperBeltTileImageAsset,
  'orion_nebula': asteroidOrionNebulaTileImageAsset,
  'pillars_creation': asteroidPillarsCreationTileImageAsset,
  'black_hole': asteroidBlackHoleTileImageAsset,
  'andromeda': asteroidAndromedaTileImageAsset,
  'deep_quasar': asteroidDeepQuasarTileImageAsset,
};

const List<String> asteroidTileImageAssets = [
  asteroidEarthMoonTileImageAsset,
  asteroidMarsTileImageAsset,
  asteroidBeltTileImageAsset,
  asteroidJupiterTileImageAsset,
  asteroidSaturnTileImageAsset,
  asteroidIceGiantsTileImageAsset,
  asteroidKuiperBeltTileImageAsset,
  asteroidOrionNebulaTileImageAsset,
  asteroidPillarsCreationTileImageAsset,
  asteroidBlackHoleTileImageAsset,
  asteroidAndromedaTileImageAsset,
  asteroidDeepQuasarTileImageAsset,
];

const List<String> playerShipImageAssets = [
  playerShipImageAsset,
  playerShipMarsImageAsset,
  playerShipAsteroidBeltImageAsset,
  playerShipJupiterImageAsset,
  playerShipSaturnImageAsset,
  playerShipIceGiantsImageAsset,
  playerShipKuiperBeltImageAsset,
  playerShipOrionNebulaImageAsset,
  playerShipPillarsCreationImageAsset,
  playerShipBlackHoleImageAsset,
  playerShipAndromedaImageAsset,
  playerShipDeepQuasarImageAsset,
];

const List<String> gameImageAssets = [
  asteroidTileImageAsset,
  ...asteroidTileImageAssets,
  looseMeteorImageAsset,
  ...playerShipImageAssets,
  spaceEarthMoonBackgroundAsset,
  spaceMarsBackgroundAsset,
  spaceAsteroidBeltBackgroundAsset,
  spaceJupiterBackgroundAsset,
  spaceSaturnBackgroundAsset,
  spaceIceGiantsBackgroundAsset,
  spaceKuiperBeltBackgroundAsset,
  spaceOrionNebulaBackgroundAsset,
  spacePillarsCreationBackgroundAsset,
  spaceBlackHoleBackgroundAsset,
  spaceAndromedaBackgroundAsset,
  spaceDeepQuasarBackgroundAsset,
];
