import 'package:acter/features/cross_signing/providers/notifiers/verification_notifiers.dart';
import 'package:riverpod/riverpod.dart';

/// Provider of verification state
final verificationStateProvider =
    NotifierProvider<VerificationNotifier, VerificationState>(
      () => VerificationNotifier(),
    );
