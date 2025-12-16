/// Represents a custom snippet or shortcut.
class Snippet {
  /// Creates a new instance of [Snippet].
  const Snippet({
    required this.id,
    required this.trigger,
    required this.content,
  });

  /// Creates a [Snippet] from a map.
  factory Snippet.fromMap(Map<String, dynamic> map) {
    return Snippet(
      id: map['id'] as String,
      trigger: map['trigger'] as String,
      content: map['content'] as String,
    );
  }

  /// The unique identifier for the snippet.
  final String id;

  /// The shortcut text that triggers the snippet (e.g., ";email").
  final String trigger;

  /// The content that replaces the trigger.
  final String content;

  /// Converts this snippet to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trigger': trigger,
      'content': content,
    };
  }
}
