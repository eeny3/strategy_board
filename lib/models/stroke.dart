import 'package:flutter/material.dart';

enum LineType { solid, dashed, arrow }

class Stroke {
  final List<Offset> points;
  final Color color;
  final double thickness;
  final LineType type;

  Stroke({
    required this.points,
    required this.color,
    required this.thickness,
    this.type = LineType.solid,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      // ignore: deprecated_member_use
      'color': color.value,
      'thickness': thickness,
      'type': type.name,
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    var rawPoints = json['points'] as List;
    List<Offset> loadedPoints = rawPoints.map((p) {
      return Offset(
        (p['dx'] as num).toDouble(),
        (p['dy'] as num).toDouble(),
      );
    }).toList();

    LineType loadedType = LineType.solid;
    if (json.containsKey('type') && json['type'] != null) {
      loadedType = LineType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LineType.solid,
      );
    }

    return Stroke(
      points: loadedPoints,
      color: Color(json['color'] as int),
      thickness: (json['thickness'] as num).toDouble(),
      type: loadedType,
    );
  }
}
