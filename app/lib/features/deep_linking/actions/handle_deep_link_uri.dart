import 'package:acter/features/deep_linking/actions/forward_to_object.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:acter/features/super_invites/dialogs/redeem_dialog.dart';
import 'package:acter/features/users/actions/show_global_user_dialog.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> handleDeepLinkUri({
  required BuildContext context,
  required WidgetRef ref,
  required Uri uri,
  bool throwNoError = false,
}) async {
  final lang = L10n.of(context);
  try {
    final result = parseActerUri(uri);
    final _ = switch (result.type) {
      LinkType.userId =>
        context.mounted
            ? await showUserInfoDrawer(context: context, userId: result.target)
            : null,
      LinkType.superInvite =>
        context.mounted
            ? await showReedemTokenDialog(context, ref, result.target)
            : null,
      LinkType.spaceObject =>
        context.mounted ? await forwardToObject(context, ref, result) : null,
      _ => EasyLoading.showError(
        lang.deepLinkNotSupported(result.type),
        duration: const Duration(seconds: 3),
      ),
    };
  } on UriParseError catch (e) {
    if (throwNoError) {
      rethrow;
    }
    EasyLoading.showError(
      lang.deepLinkNotSupported(e),
      duration: const Duration(seconds: 3),
    );
    return;
  }
}
