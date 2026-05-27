import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/game/cubit/cubit.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/title/content/title_language_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TitleTopBar extends StatelessWidget {
  const TitleTopBar({required this.selectedLocale, super.key});

  final Locale? selectedLocale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentLanguageCode =
        selectedLocale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final currentLanguage = switch (currentLanguageCode) {
      'pt' => l10n.titleLanguagePortuguese,
      _ => l10n.titleLanguageEnglish,
    };

    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 12,
        children: [
          PopupMenuButton<Locale>(
            tooltip: l10n.titleLanguageTooltip,
            color: const Color(0xFF101835),
            onSelected: context.read<AppLocaleCubit>().setLocale,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: const Locale('en'),
                  child: TitleLanguageMenuItem(
                    selected: currentLanguageCode == 'en',
                    label: l10n.titleLanguageEnglish,
                  ),
                ),
                PopupMenuItem(
                  value: const Locale('pt'),
                  child: TitleLanguageMenuItem(
                    selected: currentLanguageCode == 'pt',
                    label: l10n.titleLanguagePortuguese,
                  ),
                ),
              ];
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x55FFFFFF)),
                borderRadius: BorderRadius.circular(999),
                color: const Color(0x33101835),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 14),
                    child: Text(
                      currentLanguage,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFEAF7FF),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox.square(
                    dimension: 44,
                    child: Center(
                      child: Icon(
                        Icons.language_rounded,
                        color: Color(0xFFEAF7FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<AudioCubit, AudioState>(
            builder: (context, state) {
              final isMuted = state.volume == 0;
              return IconButton.filledTonal(
                tooltip: isMuted
                    ? l10n.audioUnmuteTooltip
                    : l10n.audioMuteTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x33101835),
                  foregroundColor: const Color(0xFFEAF7FF),
                  side: const BorderSide(color: Color(0x55FFFFFF)),
                ),
                icon: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                ),
                onPressed: () => context.read<AudioCubit>().toggleVolume(),
              );
            },
          ),
        ],
      ),
    );
  }
}
