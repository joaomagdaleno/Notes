import 'package:flutter/material.dart';

/// Represents a single point in a stroke.
class Point {
  /// Creates a point.
  const Point(this.x, this.y, [this.pressure = 1.0]);

  /// Creates a point from JSON.
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['p'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// The x coordinate.
  final double x;

  /// The y coordinate.
  final double y;

  /// The pressure (0.0 to 1.0).
  final double pressure;

  /// Converts to JSON.
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
  /// Creates a stroke.
  const Stroke({
    required this.points,
    required this.color,
    required this.width,
  });

  /// Creates a stroke from JSON.
  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List)
          .map((e) => Point.fromJson(e as Map<String, dynamic>))
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
    );
  }

  /// The list of points in the stroke.
  final List<Point> points;

  /// The color of the stroke.
  final Color color;

  /// The width of the stroke.
  final double width;

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'color': color.toARGB32(),
      'width': width,
    };
  }
}
