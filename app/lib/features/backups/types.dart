enum BackupState {
  enabling,
  resuming,
  enabled,
  downloading,
  disabling,
  creating,
  unknown,
}

BackupState stringToState(String s) {
  switch (s) {
    case 'enabling':
      return BackupState.enabling;
    case 'resuming':
      return BackupState.resuming;
    case 'enabled':
      return BackupState.enabled;
    case 'downloading':
      return BackupState.downloading;
    case 'disabling':
      return BackupState.disabling;
    case 'creating':
      return BackupState.creating;
    default:
      return BackupState.unknown;
  }
}
