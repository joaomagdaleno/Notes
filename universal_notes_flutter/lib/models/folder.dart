/// Represents a folder containing notes.
class Folder {
  /// Creates a new instance of [Folder].
  const Folder({
    required this.id,
    required this.name,
    this.isSmart = false,
    this.query,
  });

  /// Creates a [Folder] from a map.
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
      isSmart: (map['isSmart'] as int?) == 1,
      query: map['query'] as String?,
    );
  }

  /// The unique identifier for the folder.
  final String id;

  /// The name of the folder.
  final String name;

  /// Whether this is a smart folder.
  final bool isSmart;

  /// The SQL query for the smart folder.
  final String? query;

  /// Converts this folder to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isSmart': isSmart ? 1 : 0,
      'query': query,
    };
  }
}
