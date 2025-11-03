class Note {
  final String id;
  final String title;
  final String contentPreview;
  final DateTime date;
  bool isFavorite;
  bool isLocked;
  bool isInTrash;

  Note({
    String? id,
    required this.title,
    required this.contentPreview,
    required this.date,
    this.isFavorite = false,
    this.isLocked = false,
    this.isInTrash = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      contentPreview: json['contentPreview'],
      date: DateTime.parse(json['date']),
      isFavorite: json['isFavorite'] ?? false,
      isLocked: json['isLocked'] ?? false,
      isInTrash: json['isInTrash'] ?? false,
    );
  }
}
