import 'package:flutter/material.dart';

class TouchPoints {
  final Paint paint;
  final Offset? points;
  TouchPoints({
    required this.paint,
    this.points,
  });

  Map<String, dynamic> toJson() => {
        'point': {'dx': '${points?.dx}', 'dy': '${points?.dy}'},
      };
}
