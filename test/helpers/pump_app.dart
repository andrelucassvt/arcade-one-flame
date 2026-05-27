import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/game/cubit/cubit.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';

import 'helpers.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    MockNavigator? navigator,
    AppLocaleCubit? appLocaleCubit,
    PreloadCubit? preloadCubit,
    AudioCubit? audioCubit,
  }) {
    final localeCubit = appLocaleCubit ?? AppLocaleCubit();
    return pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: preloadCubit ?? MockPreloadCubit()),
        ],
        child: BlocBuilder<AppLocaleCubit, Locale?>(
          builder: (context, locale) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: navigator != null
                  ? MockNavigatorProvider(navigator: navigator, child: widget)
                  : widget,
            );
          },
        ),
      ),
    );
  }
}
