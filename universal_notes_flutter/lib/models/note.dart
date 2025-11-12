import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// Represents a single note entry.
class Note {
  /// Creates a new instance of [Note].
  Note({
    required this.title,
    required this.content,
    required this.date,
    String? id,
    this.isFavorite = false,
    this.isLocked = false,
    this.isInTrash = false,
    this.drawingJson,
    this.prefsJson,
  }) : id = id ?? uuid.v4();

  /// Creates a new instance of [Note] from a map.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String?,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      isFavorite: (map['isFavorite'] as int) == 1,
      isLocked: (map['isLocked'] as int) == 1,
      isInTrash: (map['isInTrash'] as int) == 1,
      drawingJson: map['drawingJson'] as String?,
      prefsJson: map['prefsJson'] as String?,
    );
  }

  /// The unique identifier of the note.
  final String id;
  /// The title of the note.
  String title;
  /// The content of the note.
  String content;
  /// The date and time when the note was created or last modified.
  final DateTime date;
  /// Whether the note is marked as a favorite.
  bool isFavorite;
  /// Whether the note is locked.
  bool isLocked;
  /// Whether the note is in the trash.
  bool isInTrash;
  /// The drawing data associated with the note, in JSON format.
  String? drawingJson;
  /// The preferences associated with the note, in JSON format.
  String? prefsJson;

  /// Creates a new instance of [Note].
  Note({
    required this.title,
    required this.content,
    required this.date,
    String? id,
    this.isFavorite = false,
    this.isLocked = false,
    this.isInTrash = false,
    this.drawingJson,
    this.prefsJson,
  }) : id = id ?? uuid.v4();

  /// Creates a new instance of [Note] from a map.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String?,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      isFavorite: (map['isFavorite'] as int) == 1,
      isLocked: (map['isLocked'] as int) == 1,
      isInTrash: (map['isInTrash'] as int) == 1,
      drawingJson: map['drawingJson'] as String?,
      prefsJson: map['prefsJson'] as String?,
    );
  }

  /// Converts the [Note] to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'isInTrash': isInTrash ? 1 : 0,
      'drawingJson': drawingJson,
      'prefsJson': prefsJson,
    };
  }

  /// Creates a copy of the [Note] with the given fields replaced with the new
  /// values.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    bool? isFavorite,
    bool? isLocked,
    bool? isInTrash,
    String? drawingJson,
    String? prefsJson,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      isInTrash: isInTrash ?? this.isInTrash,
      drawingJson: drawingJson ?? this.drawingJson,
      prefsJson: prefsJson ?? this.prefsJson,
    );
  }
}
