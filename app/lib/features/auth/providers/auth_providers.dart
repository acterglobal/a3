import 'package:acter/features/auth/providers/notifiers/auth_notifier.dart';
import 'package:riverpod/riverpod.dart';

final authLoadingStateProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider),
);

final authStateProvider = NotifierProvider<AuthNotifier, bool>(
  () => AuthNotifier(),
);
