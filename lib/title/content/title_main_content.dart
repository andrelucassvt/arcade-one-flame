import 'package:arcade_one/title/content/title_hero.dart';
import 'package:arcade_one/title/content/title_start_button.dart';
import 'package:flutter/material.dart';

class TitleMainContent extends StatelessWidget {
  const TitleMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Column(
      children: [
        TitleHero(isWide: isWide),
        const SizedBox(height: 36),
        const TitleStartButton(),
      ],
    );
  }
}
