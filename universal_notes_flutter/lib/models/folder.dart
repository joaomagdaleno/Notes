/// Represents a folder containing notes.
class Folder {
  /// Creates a new instance of [Folder].
  const Folder({
    required this.id,
    required this.name,
  });

  /// Creates a [Folder] from a map.
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }

  /// The unique identifier for the folder.
  final String id;

  /// The name of the folder.
  final String name;

  /// Converts this folder to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
