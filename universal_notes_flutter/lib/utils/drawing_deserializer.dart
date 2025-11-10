import 'package:flutter_drawing_board/flutter_drawing_board.dart';

PaintObject? paintContentFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    case 'Line':
      return Line.fromJson(json);
    case 'EraserObject':
      return EraserObject.fromJson(json);
    default:
      return null;
  }
}
