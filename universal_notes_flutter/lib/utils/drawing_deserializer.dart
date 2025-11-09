import 'package:flutter_drawing_board/flutter_drawing_board.dart';

DrawObject? paintContentFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    case 'SimpleLine':
      return DrawLine.fromJson(json);
    case 'Eraser':
      return DrawEraser.fromJson(json);
    default:
      return null;
  }
}
