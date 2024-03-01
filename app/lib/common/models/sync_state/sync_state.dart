import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'sync_state.freezed.dart';

@freezed
class SyncState with _$SyncState {
  const factory SyncState({
    required bool initialSync,
    String? errorMsg,
    int? countDown,
    int? nextRetry,
  }) = _NewSyncState;
}
