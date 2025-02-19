import 'package:acter/features/super_invites/pages/invite_list_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

const Key selectInviteCodeDrawerKey = Key('select-invitation-code-drawer');

Future<SuperInviteToken?> selectSuperInviteDrawer({
  required BuildContext context,
}) async {
 return await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (context) => InviteListPage(
      onSelectInviteCode : (inviteCodeId) => Navigator.pop(context, inviteCodeId),
    ),
  );
}
