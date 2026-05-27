import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

class AppLocaleCubit extends Cubit<Locale?> {
  AppLocaleCubit() : super(null);

  void setLocale(Locale locale) {
    if (state == locale) {
      return;
    }

    emit(locale);
  }
}
