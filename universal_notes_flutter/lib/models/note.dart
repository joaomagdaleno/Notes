import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';

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
    this.folderId,
    this.syncStatus = SyncStatus.synced,
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
      collaborators: Map<String, String>.from(
        (data['collaborators'] as Map<dynamic, dynamic>?) ?? {},
      ),
      tags: List<String>.from((data['tags'] as List<dynamic>?) ?? []),
      memberIds: List<String>.from((data['memberIds'] as List<dynamic>?) ?? []),
      isFavorite: data['isFavorite'] as bool? ?? false,
      isInTrash: data['isInTrash'] as bool? ?? false,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  /// Creates a [Note] from a map (e.g. from local database).
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id:
          map['id'] as String? ??
          '', // ID might not be in map if not from DB query with ID
      title: map['title'] as String? ?? 'Untitled',
      content: map['content'] as String? ?? '',
      createdAt: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
          : DateTime.now(),
      lastModified: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
          : DateTime.now(), // Map 'date' to lastModified/createdAt for now
      ownerId: map['ownerId'] as String? ?? 'local',
      isFavorite: (map['isFavorite'] as int?) == 1,
      isInTrash: (map['isInTrash'] as int?) == 1,
      folderId: map['folderId'] as String?,
      syncStatus: map['syncStatus'] != null
          ? SyncStatus.values[map['syncStatus'] as int]
          : SyncStatus.synced,
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

  /// The folder ID if any
  final String? folderId;

  /// The status of synchronization.
  final SyncStatus syncStatus;

  /// Returns the date to display (usually lastModified).
  DateTime get date => lastModified;

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
    String? folderId,
    SyncStatus? syncStatus,
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
      folderId: folderId ?? this.folderId,
      syncStatus: syncStatus ?? this.syncStatus,
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

  /// Converts this note to a map for local database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': lastModified.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'isInTrash': isInTrash ? 1 : 0,
      'folderId': folderId,
      'syncStatus': syncStatus.index,
    };
  }
}
