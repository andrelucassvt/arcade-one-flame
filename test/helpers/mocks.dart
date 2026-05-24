import 'package:arcade_one/loading/loading.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPreloadCubit extends MockCubit<PreloadState>
    implements PreloadCubit {}

class MockAudioCache extends Mock implements AudioCache {}
