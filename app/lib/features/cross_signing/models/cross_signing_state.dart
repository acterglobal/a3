import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cross_signing_state.freezed.dart';

@freezed
class CrossSigningState with _$CrossSigningState {
  const factory CrossSigningState.init() = _CrossSigningStateInit;

  const factory CrossSigningState.request({
    required VerificationEvent event,
  }) = _CrossSigningStateRequest;

  const factory CrossSigningState.ready({
    required VerificationEvent event,
  }) = _CrossSigningStateReady;

  const factory CrossSigningState.start({
    required VerificationEvent event,
  }) = _CrossSigningStateStart;

  const factory CrossSigningState.cancel({
    required VerificationEvent event,
  }) = _CrossSigningStateCancel;

  const factory CrossSigningState.accept({
    required VerificationEvent event,
  }) = _CrossSigningStateAccept;

  const factory CrossSigningState.key({
    required VerificationEvent event,
  }) = _CrossSigningStateKey;

  const factory CrossSigningState.mac({
    required VerificationEvent event,
  }) = _CrossSigningStateMac;

  const factory CrossSigningState.done({
    required VerificationEvent event,
  }) = _CrossSigningStateDone;
}
