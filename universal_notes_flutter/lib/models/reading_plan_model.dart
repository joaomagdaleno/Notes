/// Model for a reading plan (a collection of notes to read in order).
class ReadingPlan {
  /// Creating a new [ReadingPlan].
  ReadingPlan({
    required this.id,
    required this.title,
    required this.noteIds,
    this.currentIndex = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Unique identifier of the plan.
  final String id;

  /// Human-readable title of the plan.
  final String title;

  /// Ordered list of note IDs in this plan.
  final List<String> noteIds;

  /// Index of the current note being read.
  final int currentIndex;

  /// When this plan was created.
  final DateTime createdAt;

  /// Creates [ReadingPlan] from a map.
  factory ReadingPlan.fromMap(Map<String, dynamic> map) {
    return ReadingPlan(
      id: map['id'] as String,
      title: map['title'] as String,
      noteIds: (map['noteIds'] as String).split(','),
      currentIndex: map['currentIndex'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Converts this to a map for SQL.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'noteIds': noteIds.join(','),
      'currentIndex': currentIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy with optional new values.
  ReadingPlan copyWith({
    String? title,
    List<String>? noteIds,
    int? currentIndex,
  }) {
    return ReadingPlan(
      id: id,
      title: title ?? this.title,
      noteIds: noteIds ?? this.noteIds,
      currentIndex: currentIndex ?? this.currentIndex,
      createdAt: createdAt,
    );
  }
}
