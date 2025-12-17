import 'dart:convert';

enum NoteEventType {
  insert,
  delete,
  format,
  image_insert,
  unknown,
}

class NoteEvent {
  const NoteEvent({
    required this.id,
    required this.noteId,
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  factory NoteEvent.fromMap(Map<String, dynamic> map) {
    return NoteEvent(
      id: map['id'] as String,
      noteId: map['noteId'] as String,
      type: _parseType(map['type'] as String),
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  final String id;
  final String noteId;
  final NoteEventType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'type': type.name,
      'payload': jsonEncode(payload),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static NoteEventType _parseType(String type) {
    return NoteEventType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NoteEventType.unknown,
    );
  }
}
