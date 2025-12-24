/// Model for a reading bookmark in the Zen reading mode.
///
/// Represents a saved position in a note for later reading.
class ReadingBookmark {
  /// Creates a new [ReadingBookmark].
  const ReadingBookmark({
    required this.id,
    required this.noteId,
    required this.position,
    required this.createdAt,
    this.name,
    this.excerpt,
  });

  /// Creates a [ReadingBookmark] from a JSON map.
  factory ReadingBookmark.fromJson(Map<String, dynamic> json) {
    return ReadingBookmark(
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      name: json['name'] as String?,
      excerpt: json['excerpt'] as String?,
    );
  }

  /// Unique identifier for this bookmark.
  final String id;

  /// The ID of the note this bookmark belongs to.
  final String noteId;

  /// The character position in the note content.
  final int position;

  /// When this bookmark was created.
  final DateTime createdAt;

  /// Optional name for the bookmark.
  final String? name;

  /// Optional excerpt of text at this position.
  final String? excerpt;

  /// Converts this bookmark to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'noteId': noteId,
      'position': position,
      'createdAt': createdAt.toIso8601String(),
      'name': name,
      'excerpt': excerpt,
    };
  }

  /// Creates a copy of this bookmark with optional new values.
  ReadingBookmark copyWith({
    String? id,
    String? noteId,
    int? position,
    DateTime? createdAt,
    String? name,
    String? excerpt,
  }) {
    return ReadingBookmark(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      excerpt: excerpt ?? this.excerpt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingBookmark &&
        other.id == id &&
        other.noteId == noteId &&
        other.position == position &&
        other.createdAt == createdAt &&
        other.name == name &&
        other.excerpt == excerpt;
  }

  @override
  int get hashCode {
    return Object.hash(id, noteId, position, createdAt, name, excerpt);
  }

  @override
  String toString() {
    return 'ReadingBookmark(id: $id, noteId: $noteId, position: $position)';
  }
}
