import 'package:flutter/material.dart';

class TitleLanguageMenuItem extends StatelessWidget {
  const TitleLanguageMenuItem({
    required this.selected,
    required this.label,
    super.key,
  });

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? const Color(0xFFFFC857) : const Color(0xFF9DB2D7),
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFEAF7FF),
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
