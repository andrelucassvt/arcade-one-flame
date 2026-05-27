import 'package:arcade_one/title/content/title_hero.dart';
import 'package:arcade_one/title/content/title_mission_console.dart';
import 'package:arcade_one/title/content/title_start_button.dart';
import 'package:flutter/material.dart';

class TitleMainContent extends StatelessWidget {
  const TitleMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final hero = TitleHero(isWide: isWide);
        const console = TitleMissionConsole();
        const startButton = TitleStartButton();

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(flex: 6, child: hero),
                  const SizedBox(width: 44),
                  const Expanded(flex: 4, child: console),
                ],
              ),
              const SizedBox(height: 36),
              startButton,
            ],
          );
        }

        return Column(
          children: [
            hero,
            const SizedBox(height: 22),
            startButton,
            const SizedBox(height: 28),
            console,
          ],
        );
      },
    );
  }
}
