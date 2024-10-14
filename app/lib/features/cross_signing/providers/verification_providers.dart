import 'package:acter/features/cross_signing/providers/notifiers/verification_notifiers.dart';
import 'package:acter/features/main/providers/client_providers.dart';
import 'package:riverpod/riverpod.dart';

/// Provider of verification state
final verificationStateProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return VerificationNotifier(ref: ref, client: client);
});
