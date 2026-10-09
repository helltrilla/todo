/// Represents the current lifecycle state of cloud synchronization.
enum SyncStatus {
  idle,
  syncing,
  success,
  error;

  bool get isSyncing => this == SyncStatus.syncing;
  bool get hasError => this == SyncStatus.error;
  bool get isSuccess => this == SyncStatus.success;
  bool get isIdle => this == SyncStatus.idle;
}
