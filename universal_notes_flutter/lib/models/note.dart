import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_notes_flutter/models/package.flutter/foundation.dart';

/// A class representing a single note, adapted for Firestore.
@immutable
class Note {
  /// Creates a new instance of [Note].
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.lastModified,
    required this.ownerId,
    this.collaborators = const {},
    this.tags = const [],
    this.memberIds = const [],
    this.isFavorite = false,
    this.isInTrash = false,
    this.imageUrl,
  });

  /// Creates a [Note] from a Firestore document snapshot.
  factory Note.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Note(
      id: snapshot.id,
      title: data['title'] as String,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastModified: (data['lastModified'] as Timestamp).toDate(),
      ownerId: data['ownerId'] as String,
      collaborators: Map<String, String>.from(data['collaborators'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      isFavorite: data['isFavorite'] as bool? ?? false,
      isInTrash: data['isInTrash'] as bool? ?? false,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  /// The unique identifier for the note (document ID).
  final String id;

  /// The title of the note.
  final String title;

  /// The content of the note.
  final String content;

  /// The date the note was created.
  final DateTime createdAt;

  /// The date the note was last modified.
  final DateTime lastModified;

  /// The ID of the user who owns the note.
  final String ownerId;

  /// A map of collaborator user IDs to their roles (e.g., 'editor', 'viewer').
  final Map<String, String> collaborators;

  /// A list of tags for the note.
  final List<String> tags;

  /// A list of user IDs who have access to this note (owner + collaborators).
  final List<String> memberIds;

  /// Whether the note is a favorite.
  final bool isFavorite;

  /// Whether the note is in the trash.
  final bool isInTrash;

  /// The URL of an attached image.
  final String? imageUrl;

  /// Creates a copy of this note but with the given fields replaced.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? lastModified,
    String? ownerId,
    Map<String, String>? collaborators,
    List<String>? tags,
    List<String>? memberIds,
    bool? isFavorite,
    bool? isInTrash,
    String? imageUrl,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      ownerId: ownerId ?? this.ownerId,
      collaborators: collaborators ?? this.collaborators,
      tags: tags ?? this.tags,
      memberIds: memberIds ?? this.memberIds,
      isFavorite: isFavorite ?? this.isFavorite,
      isInTrash: isInTrash ?? this.isInTrash,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Converts this note to a map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified),
      'ownerId': ownerId,
      'collaborators': collaborators,
      'tags': tags,
      'memberIds': memberIds,
      'isFavorite': isFavorite,
      'isInTrash': isInTrash,
      'imageUrl': imageUrl,
    };
  }
}
