import 'package:acter/features/cross_signing/models/cross_signing_state.dart';
import 'package:acter/features/cross_signing/providers/notifiers/cross_signing_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final crossSigningProvider = StateNotifierProvider.autoDispose
    .family<CrossSigningNotifier, CrossSigningState, Client>(
  (ref, client) => CrossSigningNotifier(ref: ref, client: client),
);
