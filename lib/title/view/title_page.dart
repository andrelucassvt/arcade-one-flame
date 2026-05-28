import 'dart:async';

import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game_control_mode.dart';
import 'package:arcade_one/title/content/title_backdrop.dart';
import 'package:arcade_one/title/content/title_main_content.dart';
import 'package:arcade_one/title/content/title_top_bar.dart';
import 'package:arcade_one/title/cubit/cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TitleView extends StatefulWidget {
  const TitleView({super.key});

  @override
  State<TitleView> createState() => _TitleViewState();

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const TitleView());
  }
}

class _TitleViewState extends State<TitleView> {
  static const _contentMaxWidth = 1040.0;

  late final TitleControlModeCubit _controlModeCubit;

  @override
  void initState() {
    super.initState();
    _controlModeCubit = TitleControlModeCubit(
      storage: context.read<StorageService>(),
    );
    unawaited(_controlModeCubit.init());
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocale = context.select<AppLocaleCubit, Locale?>(
      (cubit) => cubit.state,
    );
    final minContentHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;

    return BlocProvider.value(
      value: _controlModeCubit,
      child: BlocBuilder<TitleControlModeCubit, GameControlMode>(
        builder: (context, selectedControlMode) {
          return Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: TitleBackdrop(),
                ),
                Positioned.fill(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minContentHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _contentMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TitleTopBar(selectedLocale: selectedLocale),
                                const SizedBox(height: 32),
                                TitleMainContent(
                                  selectedControlMode: selectedControlMode,
                                  onControlModeChanged: (mode) {
                                    unawaited(
                                      context
                                          .read<TitleControlModeCubit>()
                                          .setControlMode(mode),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_controlModeCubit.close());
    super.dispose();
  }
}
