import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game_audio_assets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  AudioCubit({
    required this.deathPlayer,
    required this.bgmPlayer,
    StorageService? storage,
  }) : _storage = storage,
       super(const AudioState());

  AudioCubit.test({
    required this.deathPlayer,
    required this.bgmPlayer,
    StorageService? storage,
    double volume = 1.0,
  }) : _storage = storage,
       super(AudioState(volume: volume));

  final AudioPlayer deathPlayer;

  final AudioPlayer bgmPlayer;

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
    await deathPlayer.setVolume(volume);
    await bgmPlayer.setVolume(volume);
    if (!isClosed) {
      emit(state.copyWith(volume: volume));
    }
  }

  Future<void> toggleVolume() async {
    final newVolume = state.volume == 0 ? 1.0 : 0.0;
    await _changeVolume(newVolume);
    await _storage?.setDouble(_keyVolume, newVolume);
  }

  Future<void> startBgm() async {
    if (state.volume == 0) return;
    await bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await bgmPlayer.play(AssetSource(bgmAudioAsset), volume: state.volume);
  }

  Future<void> stopBgm() async {
    await bgmPlayer.stop();
  }

  @override
  Future<void> close() async {
    await deathPlayer.dispose();
    await bgmPlayer.dispose();
    return super.close();
  }
}
