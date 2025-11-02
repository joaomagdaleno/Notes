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
}
