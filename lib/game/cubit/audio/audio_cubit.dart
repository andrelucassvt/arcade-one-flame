import 'dart:async';

import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/gen/assets.gen.dart';
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
  static const double engineVolumeFactor = 0.4;
  static const _engineFadeDuration = Duration(milliseconds: 180);
  static const _engineFadeSteps = 6;

  static final _engineFadeStepDuration = Duration(
    milliseconds: _engineFadeDuration.inMilliseconds ~/ _engineFadeSteps,
  );

  Timer? _engineFadeTimer;
  Completer<void>? _engineFadeCompleter;
  double _engineCurrentVolume = 0;
  bool _isEngineLoopPlaying = false;

  /// Carrega o volume persistido. Deve ser chamado logo após a criação.
  Future<void> init() async {
    if (_storage == null) return;
    final saved = await _storage.getDouble(_keyVolume);
    if (saved != null) {
      await _changeVolume(saved);
    }
  }

  Future<void> _changeVolume(double volume) async {
    _cancelEngineFade();
    final engineVolume = volume * engineVolumeFactor;
    _engineCurrentVolume = engineVolume;
    await enginePlayer.setVolume(engineVolume);
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

  Future<void> startEngineLoop() async {
    if (state.volume == 0) {
      return;
    }

    final targetVolume = state.volume * engineVolumeFactor;
    if (_isEngineLoopPlaying) {
      await _fadeEngineVolume(to: targetVolume);
      return;
    }

    _cancelEngineFade();
    _engineCurrentVolume = 0;
    await enginePlayer.setReleaseMode(ReleaseMode.loop);
    await enginePlayer.play(
      AssetSource(Assets.audio.engineFire),
      volume: 0,
    );
    _isEngineLoopPlaying = true;
    await _fadeEngineVolume(to: targetVolume);
  }

  Future<void> stopEngineLoop() async {
    if (!_isEngineLoopPlaying) {
      _cancelEngineFade();
      return;
    }

    await _fadeEngineVolume(to: 0, stopAfterFade: true);
    _isEngineLoopPlaying = false;
  }

  @override
  Future<void> close() async {
    _cancelEngineFade();
    await _disposeThrustTapPool();
    await enginePlayer.dispose();
    await deathPlayer.dispose();
    return super.close();
  }

  Future<void> _fadeEngineVolume({
    required double to,
    bool stopAfterFade = false,
  }) {
    _cancelEngineFade();

    final from = _engineCurrentVolume;
    final completer = Completer<void>();
    _engineFadeCompleter = completer;

    var step = 0;
    _engineFadeTimer = Timer.periodic(_engineFadeStepDuration, (timer) {
      step += 1;
      final progress = step / _engineFadeSteps;
      final volume = from + (to - from) * progress;
      _engineCurrentVolume = volume;
      unawaited(enginePlayer.setVolume(volume));

      if (step < _engineFadeSteps) {
        return;
      }

      timer.cancel();
      _engineFadeTimer = null;
      _engineCurrentVolume = to;
      unawaited(
        enginePlayer.setVolume(to).then((_) async {
          if (stopAfterFade) {
            await enginePlayer.stop();
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
          if (identical(_engineFadeCompleter, completer)) {
            _engineFadeCompleter = null;
          }
        }),
      );
    });

    return completer.future;
  }

  void _cancelEngineFade() {
    _engineFadeTimer?.cancel();
    _engineFadeTimer = null;
    final completer = _engineFadeCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _engineFadeCompleter = null;
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
