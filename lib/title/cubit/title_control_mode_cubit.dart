import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game_control_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TitleControlModeCubit extends Cubit<GameControlMode> {
  TitleControlModeCubit({required StorageService storage})
    : _storage = storage,
      super(GameControlMode.touch);

  final StorageService _storage;

  static const _keyControlMode = 'title_control_mode';

  /// Carrega o modo de controle persistido.
  Future<void> init() async {
    final saved = await _storage.getString(_keyControlMode);
    if (saved == null) {
      return;
    }

    final mode = _controlModeFromName(saved);
    if (mode != null && !isClosed) {
      emit(mode);
    }
  }

  Future<void> setControlMode(GameControlMode mode) async {
    if (state == mode) {
      return;
    }

    await _storage.setString(_keyControlMode, mode.name);
    if (!isClosed) {
      emit(mode);
    }
  }

  GameControlMode? _controlModeFromName(String name) {
    for (final mode in GameControlMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return null;
  }
}
