enum RecoveryState { incomplete, enabled, disabled, unknown }

RecoveryState stringToState(String s) {
  return switch (s) {
    'incomplete' => RecoveryState.incomplete,
    'enabled' => RecoveryState.enabled,
    'disabled' => RecoveryState.disabled,
    _ => RecoveryState.unknown,
  };
}
