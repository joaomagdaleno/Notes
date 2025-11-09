import 'package:flutter_drawing_board/flutter_drawing_board.dart';

PaintContent? paintContentFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    case 'StraightLine':
      return StraightLine.fromJson(json);
    case 'Eraser':
      return Eraser.fromJson(json);
    // Add other supported types from the library if needed.
    // For now, these are the two used in the app.
    default:
      // Return null or throw an exception for unsupported types.
      return null;
  }
}
