class Note {
  final String id;
  final String title;
  final String contentPreview;
  final DateTime date;
  bool isFavorite;

  Note({
    String? id,
    required this.title,
    required this.contentPreview,
    required this.date,
    this.isFavorite = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
