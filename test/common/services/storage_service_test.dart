import 'package:arcade_one/common/services/shared_preferences_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesStorageService', () {
    late SharedPreferencesStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = SharedPreferencesStorageService(prefs);
    });

    group('int', () {
      test('getInt returns null for missing key', () async {
        expect(await storage.getInt('missing'), isNull);
      });

      test('setInt and getInt round-trip', () async {
        await storage.setInt('count', 42);
        expect(await storage.getInt('count'), 42);
      });
    });

    group('double', () {
      test('getDouble returns null for missing key', () async {
        expect(await storage.getDouble('missing'), isNull);
      });

      test('setDouble and getDouble round-trip', () async {
        await storage.setDouble('score', 3.14);
        expect(await storage.getDouble('score'), closeTo(3.14, 0.0001));
      });
    });

    group('String', () {
      test('getString returns null for missing key', () async {
        expect(await storage.getString('missing'), isNull);
      });

      test('setString and getString round-trip', () async {
        await storage.setString('locale', 'pt');
        expect(await storage.getString('locale'), 'pt');
      });
    });

    group('bool', () {
      test('getBool returns null for missing key', () async {
        expect(await storage.getBool('missing'), isNull);
      });

      test('setBool and getBool round-trip (true)', () async {
        await storage.setBool('flag', value: true);
        expect(await storage.getBool('flag'), isTrue);
      });

      test('setBool and getBool round-trip (false)', () async {
        await storage.setBool('flag', value: false);
        expect(await storage.getBool('flag'), isFalse);
      });
    });

    group('remove', () {
      test('remove apaga chave existente', () async {
        await storage.setString('key', 'value');
        await storage.remove('key');
        expect(await storage.getString('key'), isNull);
      });

      test('remove de chave inexistente não lança erro', () async {
        await expectLater(storage.remove('nope'), completes);
      });
    });
  });
}
