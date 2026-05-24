# Arcade One

Flutter/Dart game app generated from Very Good CLI, using Bloc/Cubit for UI state and Flame for the playable scene.

## Stack

- Dart `^3.11.0` and Flutter `^3.41.0`
- `flutter_bloc`/`bloc` for Cubits, `flame`/`flame_audio` for gameplay
- Very Good Analysis plus `bloc_lint`; generated files in `lib/gen` and `lib/l10n/gen` are analyzer-excluded
- Flutter flavors: `development`, `staging`, `production`

## Estrutura

- `lib/main_*.dart` — flavor entry points that call `bootstrap(() => const App())`
- `lib/bootstrap.dart` — global Flutter error logging, Bloc observer, Poppins license registration, `runApp`
- `lib/app/` — global providers, theme, l10n delegates, and initial `LoadingPage`
- `lib/loading/` — asset preload Cubit, loading screen, animated progress bar
- `lib/title/` — title screen and Start button navigation
- `lib/game/` — Flame game, audio Cubit, entities, obstacle components, HUD components, game page
- `lib/l10n/` — ARB files, generated localizations, and `context.l10n`
- `assets/` — audio, image spritesheet, and Poppins license assets
- `test/` — mirrors feature structure and contains helpers in `test/helpers/`

## Comandos

- `flutter run --flavor development --target lib/main_development.dart` — run development flavor
- `flutter run --flavor staging --target lib/main_staging.dart` — run staging flavor
- `flutter run --flavor production --target lib/main_production.dart` — run production flavor
- `flutter test --coverage --test-randomize-ordering-seed random` — run the project test suite as documented
- `dart run bloc_tools:bloc lint .` — run Bloc-specific lint checks
- `flutter gen-l10n` — regenerate `lib/l10n/gen` after ARB changes

## Convenções

- Use Cubits for state management in the existing style; preload state lives in `loading`, audio state lives in `game`.
- Navigation is currently manual with `Navigator.pushReplacement` and `MaterialPageRoute`; there is no router package.
- Add user-facing strings in `lib/l10n/arb/app_en.arb` and access them through `context.l10n`.
- Keep generated files (`lib/gen/*`, `lib/l10n/gen/*`) treated as generated output, not hand-authored code.
- Tests should follow the existing mirrored feature structure and reuse `test/helpers/pump_app.dart` for widget setup.

## Gotchas

- All three flavor entry points currently do the same thing; flavor-specific setup belongs in `bootstrap.dart` where the existing comment marks it.
- `PreloadCubit` loads only `Assets.audio.background`, `Assets.audio.effect`, and `Assets.images.unicornAnimation.path`; new game assets need preload updates if they must be cached before gameplay.
- `GamePage` expects a `PreloadCubit` above it because it reads the preloaded audio and image caches.
- The best distance is kept only in the current `ArcadeOne` instance; there is no local persistence yet.

## Não fazer

- Do not run `flutter pub upgrade` unless explicitly asked.
- Do not hardcode visible UI strings in widgets; use ARB/l10n.
- Do not hand-edit generated localization or asset files.
- Do not replace the current `Navigator` flow with a router package unless the task is specifically about navigation architecture.

## 📖 Documentação de Flows

Para qualquer feature ou fluxo, verifique a pasta `./flow/`: leia os títulos dos arquivos `.md` disponíveis e, se algum for relevante para a tarefa atual, leia-o antes de implementar ou debugar. Use `/flow <nome>` para criar ou atualizar flows individuais.
