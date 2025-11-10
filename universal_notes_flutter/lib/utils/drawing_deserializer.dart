import 'package:flutter_drawing_board/flutter_drawing_board.dart';

PaintContent? paintContentFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    case 'SimpleLine':
      return SimpleLine.fromJson(json);
    case 'Eraser':
      return Eraser.fromJson(json);
    default:
      return null;
  }
}
