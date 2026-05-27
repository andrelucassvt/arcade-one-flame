import 'dart:async';

import 'package:arcade_one/app/cubit/cubit.dart';
import 'package:arcade_one/common/services/shared_preferences_storage_service.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/loading/loading.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget {
  const App({required this.prefs, super.key});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<StorageService>(
      create: (_) => SharedPreferencesStorageService(prefs),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) {
              final cubit =
                  AppLocaleCubit(storage: ctx.read<StorageService>());
              unawaited(cubit.init());
              return cubit;
            },
          ),
          BlocProvider(
            create: (_) {
              final cubit = PreloadCubit(
                Images(prefix: ''),
                AudioCache(prefix: ''),
              );
              unawaited(cubit.loadSequentially());
              return cubit;
            },
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLocaleCubit, Locale?>(
      builder: (context, locale) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          theme: ThemeData(
            primaryColor: const Color(0xFF2A48DF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2A48DF),
              foregroundColor: Color(0xFFFFFFFF),
            ),
            colorScheme: ColorScheme.fromSwatch(
              accentColor: const Color(0xFF2A48DF),
            ),
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                  const Color(0xFF2A48DF),
                ),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoadingPage(),
        );
      },
    );
  }
}
