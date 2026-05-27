import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/title/content/title_backdrop.dart';
import 'package:arcade_one/title/content/title_main_content.dart';
import 'package:arcade_one/title/content/title_top_bar.dart';
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
  @override
  Widget build(BuildContext context) {
    final selectedLocale = context.select<AppLocaleCubit, Locale?>(
      (cubit) => cubit.state,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          const Positioned.fill(
            child: TitleBackdrop(),
          ),
          Positioned.fill(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical,
              ),
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
                        const Spacer(),
                        const TitleMainContent(),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
