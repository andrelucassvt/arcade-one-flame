import 'dart:async';

import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/common/services/storage_service.dart';
import 'package:arcade_one/game/game.dart';
import 'package:arcade_one/title/content/title_backdrop.dart';
import 'package:arcade_one/title/content/title_main_content.dart';
import 'package:arcade_one/title/content/title_ship_selection_sheet.dart';
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
  late final TitleShipSelectionCubit _shipSelectionCubit;
  late final StorageService _storage;
  double _bestDistanceKm = 0;

  @override
  void initState() {
    super.initState();
    _storage = context.read<StorageService>();
    _controlModeCubit = TitleControlModeCubit(
      storage: _storage,
    );
    _shipSelectionCubit = TitleShipSelectionCubit(storage: _storage);
    unawaited(_controlModeCubit.init());
    unawaited(_initShipSelection());
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocale = context.select<AppLocaleCubit, Locale?>(
      (cubit) => cubit.state,
    );
    final minContentHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _controlModeCubit),
        BlocProvider.value(value: _shipSelectionCubit),
      ],
      child: BlocBuilder<TitleControlModeCubit, GameControlMode>(
        builder: (context, selectedControlMode) {
          return BlocBuilder<TitleShipSelectionCubit, PlayerShipSkin>(
            builder: (context, selectedShip) {
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
                          constraints: BoxConstraints(
                            minHeight: minContentHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                18,
                                24,
                                28,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: _contentMaxWidth,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TitleTopBar(
                                      selectedLocale: selectedLocale,
                                    ),
                                    const SizedBox(height: 32),
                                    TitleMainContent(
                                      selectedControlMode: selectedControlMode,
                                      selectedShip: selectedShip,
                                      bestDistanceKm: _bestDistanceKm,
                                      onShipSelectorPressed: () =>
                                          _showShipSelectionSheet(
                                            context,
                                            selectedShip,
                                          ),
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
          );
        },
      ),
    );
  }

  Future<void> _initShipSelection() async {
    final bestDistanceKm = await _storage.getDouble(bestDistanceStorageKey);
    if (!mounted) {
      return;
    }

    setState(() {
      _bestDistanceKm = bestDistanceKm ?? 0;
    });
    await _shipSelectionCubit.init(bestDistanceKm: _bestDistanceKm);
  }

  void _showShipSelectionSheet(
    BuildContext context,
    PlayerShipSkin selectedShip,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF0B1024),
        barrierColor: const Color(0xCC000000),
        builder: (_) {
          return TitleShipSelectionSheet(
            selectedShip: selectedShip,
            bestDistanceKm: _bestDistanceKm,
            onShipSelected: (ship) {
              unawaited(
                _shipSelectionCubit.setShip(
                  ship,
                  bestDistanceKm: _bestDistanceKm,
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_controlModeCubit.close());
    unawaited(_shipSelectionCubit.close());
    super.dispose();
  }
}
