class Note {
  final String id;
  final String title;
  final String contentPreview;
  final DateTime date;

  Note({
    String? id,
    required this.title,
    required this.contentPreview,
    required this.date,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
