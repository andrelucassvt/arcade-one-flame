import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameJoystick extends StatefulWidget {
  const GameJoystick({
    required this.onDirectionChanged,
    required this.onReleased,
    super.key,
  });

  final ValueChanged<Vector2> onDirectionChanged;
  final VoidCallback onReleased;

  @override
  State<GameJoystick> createState() => _GameJoystickState();
}

class _GameJoystickState extends State<GameJoystick> {
  static const _size = 104.0;
  static const _knobSize = 40.0;
  static const _deadZone = 0.14;

  final ValueNotifier<Offset> _knobOffset = ValueNotifier(Offset.zero);

  @override
  void dispose() {
    _knobOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const maxOffset = (_size - _knobSize) / 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _updateFromLocalPosition(details.localPosition),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onPanStart: (details) => _updateFromLocalPosition(details.localPosition),
      onPanUpdate: (details) => _updateFromLocalPosition(details.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: SizedBox.square(
        dimension: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x66111827),
            border: Border.all(color: const Color(0xAA57E4FF), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5557E4FF),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: ValueListenableBuilder<Offset>(
              valueListenable: _knobOffset,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: offset * maxOffset,
                  child: child,
                );
              },
              child: SizedBox.square(
                dimension: _knobSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFC857),
                    border: Border.all(
                      color: const Color(0xFFE8F7FF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateFromLocalPosition(Offset localPosition) {
    const center = Offset(_size / 2, _size / 2);
    final raw = localPosition - center;
    const radius = _size / 2;
    final distance = raw.distance;
    final normalizedDistance = (distance / radius).clamp(0.0, 1.0);
    final angle = math.atan2(raw.dy, raw.dx);
    final unit = normalizedDistance == 0
        ? Offset.zero
        : Offset(math.cos(angle), math.sin(angle));
    final knobOffset = unit * normalizedDistance;

    _knobOffset.value = knobOffset;

    if (normalizedDistance < _deadZone) {
      widget.onReleased();
      return;
    }

    widget.onDirectionChanged(Vector2(knobOffset.dx, knobOffset.dy));
  }

  void _release() {
    _knobOffset.value = Offset.zero;
    widget.onReleased();
  }
}
