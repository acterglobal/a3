import 'package:acter/features/auth/providers/notifiers/auth_notifier.dart';
import 'package:riverpod/riverpod.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>(
  (ref) => AuthStateNotifier(ref),
);
