/// Model for tracking reading statistics and goals.
class ReadingStats {
  /// Creates a new [ReadingStats].
  const ReadingStats({
    required this.noteId,
    this.totalReadingTimeSeconds = 0,
    this.lastReadPosition = 0,
    this.readingGoalMinutes = 0,
    this.lastOpenedAt,
  });

  /// Creates a [ReadingStats] from a Map.
  factory ReadingStats.fromMap(Map<String, dynamic> map) {
    return ReadingStats(
      noteId: map['noteId'] as String,
      totalReadingTimeSeconds: map['totalReadingTimeSeconds'] as int? ?? 0,
      lastReadPosition: map['lastReadPosition'] as int? ?? 0,
      readingGoalMinutes: map['readingGoalMinutes'] as int? ?? 0,
      lastOpenedAt: map['lastOpenedAt'] != null
          ? DateTime.parse(map['lastOpenedAt'] as String)
          : null,
    );
  }

  /// The ID of the note these stats belong to.
  final String noteId;

  /// Total time spent reading this note in seconds.
  final int totalReadingTimeSeconds;

  /// The last read position in the note.
  final int lastReadPosition;

  /// The reading goal for this note in minutes.
  final int readingGoalMinutes;

  /// When the note was last opened for reading.
  final DateTime? lastOpenedAt;

  /// Converts this to a Map.
  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'totalReadingTimeSeconds': totalReadingTimeSeconds,
      'lastReadPosition': lastReadPosition,
      'readingGoalMinutes': readingGoalMinutes,
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of these stats with optional new values.
  ReadingStats copyWith({
    String? noteId,
    int? totalReadingTimeSeconds,
    int? lastReadPosition,
    int? readingGoalMinutes,
    DateTime? lastOpenedAt,
  }) {
    return ReadingStats(
      noteId: noteId ?? this.noteId,
      totalReadingTimeSeconds:
          totalReadingTimeSeconds ?? this.totalReadingTimeSeconds,
      lastReadPosition: lastReadPosition ?? this.lastReadPosition,
      readingGoalMinutes: readingGoalMinutes ?? this.readingGoalMinutes,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
