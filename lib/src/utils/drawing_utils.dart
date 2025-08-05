import 'package:flutter/material.dart';

enum DrawingMode { pen, text, erase, none }

class DrawingPoint {
  final Offset point;
  final Paint paint;
  final bool isErase;
  final String? text;
  final TextStyle? textStyle;

  DrawingPoint({
    required this.point,
    required this.paint,
    this.isErase = false,
    this.text,
    this.textStyle,
  });
}

class DrawingArea {
  final List<DrawingPoint> points;
  final Offset? textPosition;
  final String? text;
  final TextStyle? textStyle;

  DrawingArea({
    required this.points,
    this.textPosition,
    this.text,
    this.textStyle,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final List<DrawingArea> drawingHistory;

  DrawingPainter({
    required this.points,
    required this.drawingHistory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all points from history
    for (var area in drawingHistory) {
      _drawPoints(canvas, area.points);
    }
    // Draw current points
    _drawPoints(canvas, points);
  }

  void _drawPoints(Canvas canvas, List<DrawingPoint> points) {
    if (points.isEmpty) return;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i + 1] != null) {
        canvas.drawLine(
          points[i].point,
          points[i + 1].point,
          points[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
