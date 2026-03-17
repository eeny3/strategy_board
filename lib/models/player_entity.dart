import 'package:flutter/material.dart';

class PlayerEntity {
  final String id;
  Offset position;
  final Color color;
  final String label;

  PlayerEntity({
    required this.id,
    required this.position,
    required this.color,
    required this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': {'dx': position.dx, 'dy': position.dy},
      // ignore: deprecated_member_use
      'color': color.value,
      'label': label,
    };
  }

  factory PlayerEntity.fromJson(Map<String, dynamic> json) {
    final posMap = json['position'] as Map<String, dynamic>;
    return PlayerEntity(
      id: json['id'] as String,
      position: Offset((posMap['dx'] as num).toDouble(), (posMap['dy'] as num).toDouble()),
      color: Color(json['color'] as int),
      label: json['label'] as String,
    );
  }
}
