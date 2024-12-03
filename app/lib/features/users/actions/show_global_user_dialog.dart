import 'package:acter/features/users/widgets/user_info_drawer.dart';
import 'package:flutter/material.dart';

const Key userInfoDrawer = Key('users-widgets-user-info-drawer');

Future<void> showUserInfoDrawer({
  required BuildContext context,
  required String userId,
  Key? key = userInfoDrawer,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => UserInfoDrawer(
      key: key,
      userId: userId,
    ),
  );
}
