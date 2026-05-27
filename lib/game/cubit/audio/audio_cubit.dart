import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  AudioCubit({
    required this.enginePlayer,
    required this.deathPlayer,
  }) : super(const AudioState());

  @visibleForTesting
  AudioCubit.test({
    required this.enginePlayer,
    required this.deathPlayer,
    double volume = 1.0,
  }) : super(AudioState(volume: volume));

  final AudioPlayer enginePlayer;

  final AudioPlayer deathPlayer;

  Future<void> _changeVolume(double volume) async {
    await enginePlayer.setVolume(volume);
    await deathPlayer.setVolume(volume);
    if (!isClosed) {
      emit(state.copyWith(volume: volume));
    }
  }

  Future<void> toggleVolume() async {
    if (state.volume == 0) {
      return _changeVolume(1);
    }
    return _changeVolume(0);
  }

  @override
  Future<void> close() async {
    await enginePlayer.dispose();
    await deathPlayer.dispose();
    return super.close();
  }
}
