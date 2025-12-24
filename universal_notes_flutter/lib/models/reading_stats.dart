/// Model for tracking reading statistics and goals.
class ReadingStats {
  const ReadingStats({
    required this.noteId,
    this.totalReadingTimeSeconds = 0,
    this.lastReadPosition = 0,
    this.readingGoalMinutes = 0,
    this.lastOpenedAt,
  });

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

  final String noteId;
  final int totalReadingTimeSeconds;
  final int lastReadPosition;
  final int readingGoalMinutes;
  final DateTime? lastOpenedAt;

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'totalReadingTimeSeconds': totalReadingTimeSeconds,
      'lastReadPosition': lastReadPosition,
      'readingGoalMinutes': readingGoalMinutes,
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    };
  }

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
