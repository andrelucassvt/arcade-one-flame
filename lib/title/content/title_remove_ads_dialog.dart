import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _textColor = Color(0xFFEAF7FF);

class TitleRemoveAdsDialog extends StatelessWidget {
  const TitleRemoveAdsDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const TitleRemoveAdsDialog(),
    );
    if (context.mounted) {
      context.read<RemoveAdsCubit>().clearNotice();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<RemoveAdsCubit, RemoveAdsState>(
      builder: (context, state) {
        final priceLabel = state.productPriceLabel;
        final notice = state.notice;
        final canBuy =
            state.isStoreAvailable &&
            !state.purchasePending &&
            priceLabel != null;

        return AlertDialog(
          backgroundColor: const Color(0xFF101835),
          titleTextStyle: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: _textColor),
          contentTextStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _textColor),
          title: Text(l10n.titleRemoveAdsDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.titleRemoveAdsDialogDescription),
              if (!state.isStoreAvailable) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.titleRemoveAdsStoreUnavailable,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (state.isStoreAvailable && notice != null) ...[
                const SizedBox(height: 12),
                Text(_noticeText(l10n, notice)),
              ],
              if (state.purchasePending) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.titleRemoveAdsCloseButton),
            ),
            if (!state.hasRemovedAds) ...[
              TextButton(
                onPressed: state.purchasePending
                    ? null
                    : () => context.read<RemoveAdsCubit>().restore(),
                child: Text(l10n.titleRemoveAdsRestoreButton),
              ),
              FilledButton(
                onPressed: canBuy
                    ? () => context.read<RemoveAdsCubit>().buy()
                    : null,
                child: Text(
                  priceLabel == null
                      ? l10n.titleRemoveAdsBuyButtonFallback
                      : l10n.titleRemoveAdsBuyButton(priceLabel),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _noticeText(AppLocalizations l10n, RemoveAdsNotice notice) {
    return switch (notice) {
      RemoveAdsNotice.purchaseSuccess => l10n.titleRemoveAdsPurchaseSuccess,
      RemoveAdsNotice.purchaseFailed => l10n.titleRemoveAdsPurchaseFailed,
      RemoveAdsNotice.restoreNothingFound =>
        l10n.titleRemoveAdsNothingToRestore,
      RemoveAdsNotice.storeUnavailable => l10n.titleRemoveAdsStoreUnavailable,
    };
  }
}
