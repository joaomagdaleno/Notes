import 'dart:convert';
import 'dart:io';

enum NoteEventType {
  insert,
  delete,
  format,
  image_insert,
  unknown,
}

/// Sync status for event-based synchronization.
enum SyncStatus {
  /// Event is only stored locally.
  local,

  /// Event has been synced to Firestore.
  synced,

  /// Event has a conflict with remote.
  conflict,
}

class NoteEvent {
  const NoteEvent({
    required this.id,
    required this.noteId,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.syncStatus = SyncStatus.local,
    this.deviceId,
  });

  /// Factory for creating from local SQLite map.
  factory NoteEvent.fromMap(Map<String, dynamic> map) {
    return NoteEvent(
      id: map['id'] as String,
      noteId: map['noteId'] as String,
      type: _parseType(map['type'] as String),
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      syncStatus: _parseSyncStatus(map['syncStatus'] as String?),
      deviceId: map['deviceId'] as String?,
    );
  }

  /// Factory for creating from Firestore document.
  factory NoteEvent.fromFirestore(Map<String, dynamic> map, String docId) {
    return NoteEvent(
      id: docId,
      noteId: map['noteId'] as String,
      type: _parseType(map['type'] as String),
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? 0,
      ),
      syncStatus: SyncStatus.synced,
      deviceId: map['deviceId'] as String?,
    );
  }

  final String id;
  final String noteId;
  final NoteEventType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final SyncStatus syncStatus;
  final String? deviceId;

  /// Generates a device-specific ID.
  static String get currentDeviceId {
    // Simple device ID based on hostname
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Converts to map for local SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'type': type.name,
      'payload': jsonEncode(payload),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'syncStatus': syncStatus.name,
      'deviceId': deviceId,
    };
  }

  /// Converts to map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'noteId': noteId,
      'type': type.name,
      'payload': payload, // Firestore can store maps directly
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deviceId': deviceId ?? currentDeviceId,
    };
  }

  /// Creates a copy with updated fields.
  NoteEvent copyWith({
    String? id,
    String? noteId,
    NoteEventType? type,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    SyncStatus? syncStatus,
    String? deviceId,
  }) {
    return NoteEvent(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  static NoteEventType _parseType(String type) {
    return NoteEventType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NoteEventType.unknown,
    );
  }

  static SyncStatus _parseSyncStatus(String? status) {
    if (status == null) return SyncStatus.local;
    return SyncStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => SyncStatus.local,
    );
  }
}
