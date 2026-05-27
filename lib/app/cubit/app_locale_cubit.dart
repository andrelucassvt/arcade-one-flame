import 'dart:ui';

import 'package:arcade_one/common/services/storage_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppLocaleCubit extends Cubit<Locale?> {
  AppLocaleCubit({required this.storage}) : super(null);

  final StorageService storage;

  static const _keyLocale = 'app_locale';

  /// Carrega o locale persistido. Deve ser chamado logo após a criação.
  Future<void> init() async {
    final saved = await storage.getString(_keyLocale);
    if (saved != null) {
      emit(Locale(saved));
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) {
      return;
    }

    await storage.setString(_keyLocale, locale.languageCode);
    emit(locale);
  }
}
