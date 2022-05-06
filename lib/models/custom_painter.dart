import 'package:flutter/material.dart';
import 'package:skribbl_clone/models/touch_points.dart';
import 'dart:ui' as ui;

class MyCustomPainter extends CustomPainter {
  final List<TouchPoints?> points;
  List<Offset> offsetPoints = [];

  MyCustomPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = Colors.white;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, background);
    canvas.clipRect(rect);

    for (int i = 0; i < points.length - 1; i++) {
      TouchPoints? point = points[i];
      TouchPoints? pointPlusOne = points[i + 1];
      if (point != null && pointPlusOne != null) {
        canvas.drawLine(point.points!, pointPlusOne.points!, point.paint);
      } else if (point != null && pointPlusOne == null) {
        offsetPoints.clear();
        offsetPoints.add(point.points!);
        offsetPoints
            .add(Offset(point.points!.dx + 0.1, point.points!.dy + 0.1));
        canvas.drawPoints(ui.PointMode.points, offsetPoints, point.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
