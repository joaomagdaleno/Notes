class Note {
  final String id;
  String title;
  String content;
  final DateTime date;
  bool isFavorite;
  bool isLocked;
  bool isInTrash;

  Note({
    String? id,
    required this.title,
    required this.content,
    required this.date,
    this.isFavorite = false,
    this.isLocked = false,
    this.isInTrash = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert a Note into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'isInTrash': isInTrash ? 1 : 0,
    };
  }

  // Convert a Map into a Note.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isFavorite: map['isFavorite'] == 1,
      isLocked: map['isLocked'] == 1,
      isInTrash: map['isInTrash'] == 1,
    );
  }
}
