import 'package:flutter/foundation.dart';

@immutable
class PlayerShipSkin {
  const PlayerShipSkin({
    required this.id,
    required this.assetPath,
    required this.unlockKm,
  });

  final String id;
  final String assetPath;
  final double unlockKm;

  PlayerShipSkin copyWith({
    String? id,
    String? assetPath,
    double? unlockKm,
  }) {
    return PlayerShipSkin(
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      unlockKm: unlockKm ?? this.unlockKm,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlayerShipSkin &&
            other.id == id &&
            other.assetPath == assetPath &&
            other.unlockKm == unlockKm;
  }

  @override
  int get hashCode => Object.hash(id, assetPath, unlockKm);
}
