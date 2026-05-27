import 'package:arcade_one/game/game_image_assets.dart';
import 'package:flutter/material.dart';

class TitleBackdrop extends StatelessWidget {
  const TitleBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF050816)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            spaceOrionNebulaBackgroundAsset,
            fit: BoxFit.cover,
            color: const Color(0xCCFFFFFF),
            colorBlendMode: BlendMode.modulate,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66050816),
                  Color(0xAA050816),
                  Color(0xEE050816),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Color(0x3317D8FF),
                    Color(0x00050816),
                  ],
                ),
              ),
              child: SizedBox(width: double.infinity, height: 320),
            ),
          ),
        ],
      ),
    );
  }
}
