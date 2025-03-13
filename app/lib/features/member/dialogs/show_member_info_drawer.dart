import 'package:acter/features/member/widgets/member_info_drawer.dart';
import 'package:flutter/material.dart';

const Key memberInfoDrawer = Key('members-widgets-member-info-drawer');

Future<void> showMemberInfoDrawer({
  required BuildContext context,
  required String roomId,
  required String memberId,
  bool isShowActions = true,
  Key? key = memberInfoDrawer,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder:
        (context) => MemberInfoDrawer(
          key: key,
          roomId: roomId,
          memberId: memberId,
          isShowActions: isShowActions,
        ),
  );
}
