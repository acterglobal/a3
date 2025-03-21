import 'package:acter/features/auth/providers/auth_providers.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::auth::register');

Future<void> _tryRedeem(SuperInvites superInvites, String token) async {
  // try to redeem the token in a fire-and-forget-manner
  try {
    await superInvites.redeem(token);
  } catch (error, stack) {
    _log.severe('redeeming super invite `$token` failed: $error', error, stack);
  }
}

Future<bool> register({
  required String username,
  required String password,
  required String name,
  required String token,
  required WidgetRef ref,
}) async {
  final authNotifier = ref.read(authStateProvider.notifier);
  final errorMsg = await authNotifier.register(username, password, name, token);
  if (errorMsg != null) {
    _log.severe('Failed to register', errorMsg);
    throw errorMsg;
  }
  if (token.isNotEmpty) {
    final superInvites = await ref.read(superInvitesProvider.future);
    _tryRedeem(superInvites, token);
  }
  return true;
}
