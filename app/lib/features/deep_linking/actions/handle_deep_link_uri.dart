import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/utils.dart';
import 'package:acter/features/super_invites/dialogs/redeem_dialog.dart';
import 'package:acter/features/users/actions/show_global_user_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
      LinkType.userId => context.mounted
          ? await showUserInfoDrawer(context: context, userId: result.target)
          : null,
      LinkType.superInvite => context.mounted
          ? await showReedemTokenDialog(
              context,
              ref,
              result.target,
            )
          : null,
      _ => EasyLoading.showError(
          L10n.of(context).deepLinkNotSupported(result.type),
          duration: const Duration(seconds: 3),
        ),
    };
  } on UriParseError catch (e) {
    EasyLoading.showError(
      L10n.of(context).deepLinkNotSupported(e),
      duration: const Duration(seconds: 3),
    );
    return;
  }
}
