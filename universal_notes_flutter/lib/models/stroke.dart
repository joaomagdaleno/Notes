import 'package:flutter/material.dart';

/// Represents a single point in a stroke.
class Point {
  final double x;
  final double y;
  final double pressure;

  const Point(this.x, this.y, [this.pressure = 1.0]);

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['p'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      if (pressure != 1.0) 'p': pressure,
    };
  }
}

/// Represents a continuous stroke drawn by the user.
class Stroke {
  final List<Point> points;
  final Color color;
  final double width;

  const Stroke({
    required this.points,
    required this.color,
    required this.width,
  });

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List)
          .map((e) => Point.fromJson(e as Map<String, dynamic>))
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'color': color.toARGB32(),
      'width': width,
    };
  }
}
