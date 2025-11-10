import 'package:flutter_drawing_board/flutter_drawing_board.dart';

PaintContent deserializeDrawing(Map<String, dynamic> json) {
  final type = json['type'];
  switch (type) {
    case 'line':
      return SimpleLine.fromJson(json);
    case 'eraser':
      return Eraser.fromJson(json);
    default:
      throw Exception('Tipo de desenho desconhecido: $type');
  }
}
