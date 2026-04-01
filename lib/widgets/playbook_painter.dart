import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'dart:math';
import '../models/stroke.dart';

class PlaybookPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  PlaybookPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    // Draw the active stroke being currently drawn
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    if (stroke.type == LineType.dashed) {
      final dashedPath = dashPath(
        path,
        dashArray: CircularIntervalList<double>([10.0, 10.0]),
      );
      canvas.drawPath(dashedPath, paint);
    } else if (stroke.type == LineType.arrow && stroke.points.length > 1) {
      canvas.drawPath(path, paint);
      _drawArrowHead(canvas, stroke, paint);
    } else {
      // Solid
      canvas.drawPath(path, paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;

    final p2 = stroke.points.last;
    Offset p1 = stroke.points[stroke.points.length - 2];

    // Find a point slightly further back to calculate a stable angle
    for (int i = stroke.points.length - 2; i >= 0; i--) {
      final distance = (p2 - stroke.points[i]).distance;
      if (distance >= 10.0) {
        p1 = stroke.points[i];
        break;
      }
    }

    final double dX = p2.dx - p1.dx;
    final double dY = p2.dy - p1.dy;
    final double angle = atan2(dY, dX);

    final double arrowSize = 15.0 + (stroke.thickness * 1.5);

    final Path arrowPath = Path();
    
    arrowPath.moveTo(
      p2.dx - arrowSize * cos(angle - pi / 6),
      p2.dy - arrowSize * sin(angle - pi / 6)
    );
    arrowPath.lineTo(p2.dx, p2.dy);
    arrowPath.lineTo(
      p2.dx - arrowSize * cos(angle + pi / 6),
      p2.dy - arrowSize * sin(angle + pi / 6)
    );

    // Render arrowhead with same color and thickness
    final headPaint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(arrowPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant PlaybookPainter oldDelegate) {
    return true; // We want to repaint any time the state changes
  }
}
