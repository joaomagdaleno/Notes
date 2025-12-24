import 'package:flutter/material.dart';

/// Model for a text highlight in the Zen reading mode.
///
/// Represents a highlighted section of text with optional notes.
class ReadingHighlight {
  /// Creates a new [ReadingHighlight].
  const ReadingHighlight({
    required this.id,
    required this.noteId,
    required this.startPosition,
    required this.endPosition,
    required this.createdAt,
    this.color = HighlightColor.yellow,
    this.note,
    this.text,
  });

  /// Creates a [ReadingHighlight] from a JSON map.
  factory ReadingHighlight.fromJson(Map<String, dynamic> json) {
    return ReadingHighlight(
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      startPosition: json['startPosition'] as int,
      endPosition: json['endPosition'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      color: HighlightColor.values.firstWhere(
        (c) => c.name == json['color'],
        orElse: () => HighlightColor.yellow,
      ),
      note: json['note'] as String?,
      text: json['text'] as String?,
    );
  }

  /// Unique identifier for this highlight.
  final String id;

  /// The ID of the note this highlight belongs to.
  final String noteId;

  /// The start character position of the highlight.
  final int startPosition;

  /// The end character position of the highlight.
  final int endPosition;

  /// When this highlight was created.
  final DateTime createdAt;

  /// The color of the highlight.
  final HighlightColor color;

  /// Optional note attached to this highlight.
  final String? note;

  /// The highlighted text content.
  final String? text;

  /// Gets the Flutter color for this highlight.
  Color get flutterColor => color.toColor();

  /// Converts this highlight to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'noteId': noteId,
      'startPosition': startPosition,
      'endPosition': endPosition,
      'createdAt': createdAt.toIso8601String(),
      'color': color.name,
      'note': note,
      'text': text,
    };
  }

  /// Creates a copy with optional new values.
  ReadingHighlight copyWith({
    String? id,
    String? noteId,
    int? startPosition,
    int? endPosition,
    DateTime? createdAt,
    HighlightColor? color,
    String? note,
    String? text,
  }) {
    return ReadingHighlight(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      note: note ?? this.note,
      text: text ?? this.text,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingHighlight &&
        other.id == id &&
        other.noteId == noteId &&
        other.startPosition == startPosition &&
        other.endPosition == endPosition &&
        other.createdAt == createdAt &&
        other.color == color &&
        other.note == note &&
        other.text == text;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      noteId,
      startPosition,
      endPosition,
      createdAt,
      color,
      note,
      text,
    );
  }
}

/// Available highlight colors.
enum HighlightColor {
  /// Yellow highlight.
  yellow,

  /// Green highlight.
  green,

  /// Blue highlight.
  blue,

  /// Pink highlight.
  pink,

  /// Orange highlight.
  orange
  ;

  /// Converts this enum to a Flutter [Color].
  Color toColor() {
    switch (this) {
      case HighlightColor.yellow:
        return const Color(0xFFFFF59D);
      case HighlightColor.green:
        return const Color(0xFFA5D6A7);
      case HighlightColor.blue:
        return const Color(0xFF90CAF9);
      case HighlightColor.pink:
        return const Color(0xFFF48FB1);
      case HighlightColor.orange:
        return const Color(0xFFFFCC80);
    }
  }
}
