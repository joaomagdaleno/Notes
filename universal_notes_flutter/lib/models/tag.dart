import 'package:flutter/material.dart';

/// Represents a tag that can be associated with multiple notes.
class Tag {
  /// Creates a new instance of [Tag].
  const Tag({
    required this.id,
    required this.name,
    this.color,
  });

  /// The unique identifier for the tag.
  final String id;

  /// The name of the tag.
  final String name;

  /// The optional color associated with the tag.
  final Color? color;

  /// Creates a [Tag] from a map (e.g., from a database query).
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] != null ? Color(map['color'] as int) : null,
    );
  }

  /// Converts this [Tag] to a map (e.g., for database insertion).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color?.value,
    };
  }
}
