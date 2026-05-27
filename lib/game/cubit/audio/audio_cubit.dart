import 'package:arcade_one/common/services/storage_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  AudioCubit({
    required this.enginePlayer,
    required this.deathPlayer,
    Future<AudioPool>? thrustTapPool,
    StorageService? storage,
  }) : _thrustTapPool = thrustTapPool,
       _storage = storage,
       super(const AudioState());

  AudioCubit.test({
    required this.enginePlayer,
    required this.deathPlayer,
    Future<AudioPool>? thrustTapPool,
    StorageService? storage,
    double volume = 1.0,
  }) : _thrustTapPool = thrustTapPool,
       _storage = storage,
       super(AudioState(volume: volume));

  final AudioPlayer enginePlayer;

  final AudioPlayer deathPlayer;

  final Future<AudioPool>? _thrustTapPool;

  final StorageService? _storage;

  static const _keyVolume = 'audio_volume';

  /// Carrega o volume persistido. Deve ser chamado logo após a criação.
  Future<void> init() async {
    if (_storage == null) return;
    final saved = await _storage.getDouble(_keyVolume);
    if (saved != null) {
      await _changeVolume(saved);
    }
  }

  Future<void> _changeVolume(double volume) async {
    await enginePlayer.setVolume(volume);
    await deathPlayer.setVolume(volume);
    if (!isClosed) {
      emit(state.copyWith(volume: volume));
    }
  }

  Future<void> toggleVolume() async {
    final newVolume = state.volume == 0 ? 1.0 : 0.0;
    await _changeVolume(newVolume);
    await _storage?.setDouble(_keyVolume, newVolume);
  }

  Future<void> playThrustTap() async {
    final poolFuture = _thrustTapPool;
    if (poolFuture == null || state.volume == 0) {
      return;
    }

    try {
      final pool = await poolFuture;
      await pool.start(volume: state.volume);
    } on Exception {
      // Audio feedback should not interrupt gameplay if the platform fails.
    }
  }

  @override
  Future<void> close() async {
    await _disposeThrustTapPool();
    await enginePlayer.dispose();
    await deathPlayer.dispose();
    return super.close();
  }

  Future<void> _disposeThrustTapPool() async {
    final poolFuture = _thrustTapPool;
    if (poolFuture == null) {
      return;
    }

    try {
      final pool = await poolFuture;
      await pool.dispose();
    } on Exception {
      // Ignore disposal failures from optional sound effects.
    }
  }
}
