/// Status of synchronization between local and remote storage.
enum SyncStatus {
  /// The item exists only locally and hasn't been synced to remote.
  local,

  /// The item has been modified locally and needs to be synced up.
  modified,

  /// The item is in sync with the remote storage.
  synced,

  /// The item has a conflict with remote.
  conflict,
}
