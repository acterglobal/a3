import 'package:acter/features/onboarding/providers/notifiers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>(
  (ref) => AuthStateNotifier(ref),
);

final isLoggedInProvider = StateProvider<bool>((ref) => false);
