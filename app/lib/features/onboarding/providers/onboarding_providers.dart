import 'package:acter/features/onboarding/providers/notifiers/auth_notifier.dart';
import 'package:riverpod/riverpod.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>(
  (ref) => AuthStateNotifier(ref),
);
