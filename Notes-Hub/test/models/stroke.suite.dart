@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/models/stroke.dart';

void main() {
  group('Point', () {
    test('should create a Point instance', () {
      const point = Point(10, 20, 0.5);
      expect(point.x, 10.0);
      expect(point.y, 20.0);
      expect(point.pressure, 0.5);
    });

    test('fromJson should create a Point from json', () {
      final json = {'x': 15.0, 'y': 25.0, 'p': 0.8};
      final point = Point.fromJson(json);
      expect(point.x, 15.0);
      expect(point.y, 25.0);
      expect(point.pressure, 0.8);
    });

    test('fromJson should use default pressure if missing', () {
      final json = {'x': 15.0, 'y': 25.0};
      final point = Point.fromJson(json);
      expect(point.pressure, 1.0);
    });

    test('toJson should convert a Point to json', () {
      const point = Point(10, 20, 0.5);
      final json = point.toJson();
      expect(json['x'], 10.0);
      expect(json['y'], 20.0);
      expect(json['p'], 0.5);
    });

    test('toJson should skip pressure if it is 1.0', () {
      const point = Point(10, 20);
      final json = point.toJson();
      expect(json.containsKey('p'), isFalse);
    });
  });

  group('Stroke', () {
    const points = [Point(0, 0), Point(10, 10)];
    const stroke = Stroke(
      points: points,
      color: Colors.black,
      width: 2,
    );

    test('should create a Stroke instance', () {
      expect(stroke.points, points);
      expect(stroke.color, Colors.black);
      expect(stroke.width, 2.0);
    });

    test('fromJson should create a Stroke from json', () {
      final json = {
        'points': [
          {'x': 0.0, 'y': 0.0},
          {'x': 10.0, 'y': 10.0},
        ],
        'color': Colors.red.toARGB32(),
        'width': 5.0,
      };

      final fromJson = Stroke.fromJson(json);

      expect(fromJson.points.length, 2);
      expect(fromJson.points[1].x, 10.0);
      expect(fromJson.color.toARGB32(), Colors.red.toARGB32());
      expect(fromJson.width, 5.0);
    });

    test('toJson should convert a Stroke to json', () {
      final json = stroke.toJson();

      expect((json['points'] as List).length, 2);
      expect(json['color'], Colors.black.toARGB32());
      expect(json['width'], 2.0);
    });
  });
}
