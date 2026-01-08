/// Represents a saved version of a note's content at a specific point in time.
class NoteVersion {
  /// Creates a new instance of [NoteVersion].
  const NoteVersion({
    required this.id,
    required this.noteId,
    required this.content,
    required this.date,
  });

  /// Creates a [NoteVersion] from a map.
  factory NoteVersion.fromMap(Map<String, dynamic> map) {
    return NoteVersion(
      id: map['id'] as String,
      noteId: map['noteId'] as String,
      content: map['content'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }

  /// The unique identifier for this version.
  final String id;

  /// The ID of the note this version belongs to.
  final String noteId;

  /// The JSON content of the note at this point in time.
  final String content;

  /// The date this version was saved.
  final DateTime date;

  /// Converts this version to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'content': content,
      'date': date.millisecondsSinceEpoch,
    };
  }
}
