import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:arcade_one/title/content/title_remove_ads_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TitleRemoveAdsButton extends StatelessWidget {
  const TitleRemoveAdsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<RemoveAdsCubit, RemoveAdsState>(
      buildWhen: (previous, current) =>
          previous.hasRemovedAds != current.hasRemovedAds,
      builder: (context, state) {
        if (state.hasRemovedAds) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: 260,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => TitleRemoveAdsDialog.show(context),
            icon: const Icon(Icons.block_rounded, size: 20),
            label: Text(l10n.titleRemoveAdsButton),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0x33101835),
              foregroundColor: const Color(0xFFFFD98A),
              side: const BorderSide(color: Color(0x88FFC857)),
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      },
    );
  }
}
