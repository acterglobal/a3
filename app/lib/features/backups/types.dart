enum RecoveryState {
  incomplete,
  enabled,
  disabled,
  unknown,
}

RecoveryState stringToState(String s) {
  switch (s) {
    case 'incomplete':
      return RecoveryState.incomplete;
    case 'enabled':
      return RecoveryState.enabled;
    case 'disabled':
      return RecoveryState.disabled;
    default:
      return RecoveryState.unknown;
  }
}
