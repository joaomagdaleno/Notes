import 'package:meta/meta.dart';

/// Model for a reading annotation (highlight or margin note).
@immutable
class ReadingAnnotation {
  /// Creates a new [ReadingAnnotation].
  const ReadingAnnotation({
    required this.id,
    required this.noteId,
    required this.startOffset,
    required this.endOffset,
    required this.createdAt,
    this.color,
    this.comment,
    this.textExcerpt,
  });

  /// Creates a [ReadingAnnotation] from a Map.
  factory ReadingAnnotation.fromMap(Map<String, dynamic> map) {
    return ReadingAnnotation(
      id: map['id'] as String,
      noteId: map['noteId'] as String,
      startOffset: map['startOffset'] as int,
      endOffset: map['endOffset'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      color: map['color'] as int?,
      comment: map['comment'] as String?,
      textExcerpt: map['textExcerpt'] as String?,
    );
  }

  /// Unique identifier for this annotation.
  final String id;

  /// The ID of the note this annotation belongs to.
  final String noteId;

  /// The start character position of the annotation.
  final int startOffset;

  /// The end character position of the annotation.
  final int endOffset;

  /// When this annotation was created.
  final DateTime createdAt;

  /// The color of the annotation in ARGB format.
  final int? color;

  /// Optional comment or note attached to this annotation.
  final String? comment;

  /// The text excerpt associated with this annotation.
  final String? textExcerpt;

  /// Converts this annotation to a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
      'comment': comment,
      'textExcerpt': textExcerpt,
    };
  }

  /// Creates a copy of this annotation with optional new values.
  ReadingAnnotation copyWith({
    String? id,
    String? noteId,
    int? startOffset,
    int? endOffset,
    DateTime? createdAt,
    int? color,
    String? comment,
    String? textExcerpt,
  }) {
    return ReadingAnnotation(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      comment: comment ?? this.comment,
      textExcerpt: textExcerpt ?? this.textExcerpt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingAnnotation &&
        other.id == id &&
        other.noteId == noteId &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.createdAt == createdAt &&
        other.color == color &&
        other.comment == comment &&
        other.textExcerpt == textExcerpt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      noteId,
      startOffset,
      endOffset,
      createdAt,
      color,
      comment,
      textExcerpt,
    );
  }
}
