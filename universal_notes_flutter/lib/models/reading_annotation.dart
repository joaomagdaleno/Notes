/// Model for a reading annotation (highlight or margin note).
class ReadingAnnotation {
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

  final String id;
  final String noteId;
  final int startOffset;
  final int endOffset;
  final DateTime createdAt;
  final int? color; // ARGB
  final String? comment;
  final String? textExcerpt;

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
}
