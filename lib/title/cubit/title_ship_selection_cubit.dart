import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TitleShipSelectionCubit extends Cubit<PlayerShipSkin> {
  TitleShipSelectionCubit({required StorageService storage})
    : _storage = storage,
      super(defaultPlayerShipSkin);

  final StorageService _storage;

  static const keyPlayerShip = 'title_player_ship';

  /// Carrega a nave persistida quando ela ainda existe e esta desbloqueada.
  Future<void> init({required double bestDistanceKm}) async {
    final saved = await _storage.getString(keyPlayerShip);
    if (saved == null) {
      return;
    }

    final ship = playerShipSkinById(saved);
    final isKnownShip = ship.id == saved;
    if (isKnownShip &&
        isPlayerShipUnlocked(ship, bestDistanceKm) &&
        !isClosed) {
      emit(ship);
    }
  }

  Future<void> setShip(
    PlayerShipSkin ship, {
    required double bestDistanceKm,
  }) async {
    if (state == ship || !isPlayerShipUnlocked(ship, bestDistanceKm)) {
      return;
    }

    await _storage.setString(keyPlayerShip, ship.id);
    if (!isClosed) {
      emit(ship);
    }
  }
}
