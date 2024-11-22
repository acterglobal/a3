import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/utils.dart';
import 'package:acter/features/super_invites/dialogs/redeem_dialog.dart';
import 'package:acter/features/users/actions/show_global_user_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> handleDeepLinkUri({
  required BuildContext context,
  required WidgetRef ref,
  required Uri uri,
}) async {
  try {
    final result = parseUri(uri);
    final _ = switch (result.type) {
      LinkType.userId =>
        await showUserInfoDrawer(context: context, userId: result.target),
      LinkType.superInvite => await showReedemTokenDialog(
          context,
          ref,
          result.target,
        ),
      _ => EasyLoading.showError(
          'Link ${result.type} not yet supported.',
          duration: const Duration(seconds: 3),
        ),
    };
  } on UriParseError catch (e) {
    EasyLoading.showError(
      'Uri not supported: $e',
      duration: const Duration(seconds: 3),
    );
    return;
  }
}
