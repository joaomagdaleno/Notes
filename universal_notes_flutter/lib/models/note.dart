import 'package:flutter/foundation.dart';

/// A class representing a single note.
@immutable
class Note {
  /// Creates a new instance of [Note].
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.isFavorite = false,
    this.isLocked = false,
    this.isInTrash = false,
    this.isDeleted = false,
    this.drawingJson,
    this.prefsJson,
    this.folderId,
  });

  /// The unique identifier for the note.
  final String id;
  /// The title of the note.
  final String title;
  /// The content of the note.
  final String content;
  /// The date the note was created or last modified.
  final DateTime date;
  /// Whether the note is a favorite.
  final bool isFavorite;
  /// Whether the note is locked.
  final bool isLocked;
  /// Whether the note is in the trash.
  final bool isInTrash;
  /// Whether the note is marked for deletion.
  final bool isDeleted;
  /// The drawing data for the note, as a JSON string.
  final String? drawingJson;
  /// The preferences for the note, as a JSON string.
  final String? prefsJson;
  /// The ID of the folder this note belongs to.
  final String? folderId;

  /// Creates a [Note] from a map.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      isLocked: (map['isLocked'] as int? ?? 0) == 1,
      isInTrash: (map['isInTrash'] as int? ?? 0) == 1,
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      drawingJson: map['drawingJson'] as String?,
      prefsJson: map['prefsJson'] as String?,
      folderId: map['folderId'] as String?,
    );
  }

  /// Creates a copy of this note but with the given fields replaced.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    bool? isFavorite,
    bool? isLocked,
    bool? isInTrash,
    bool? isDeleted,
    String? drawingJson,
    String? prefsJson,
    String? folderId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      isInTrash: isInTrash ?? this.isInTrash,
      isDeleted: isDeleted ?? this.isDeleted,
      drawingJson: drawingJson ?? this.drawingJson,
      prefsJson: prefsJson ?? this.prefsJson,
      folderId: folderId ?? this.folderId,
    );
  }

  /// Converts this note to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'isInTrash': isInTrash ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'drawingJson': drawingJson,
      'prefsJson': prefsJson,
      'folderId': folderId,
    };
  }
}
