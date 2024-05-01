import 'package:acter/common/widgets/room/select_room_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

const Key selectChatDrawerKey = Key('chat-widgets-select-chat-drawer');

Future<String?> selectChatDrawer({
  required BuildContext context,
  Key? key = selectChatDrawerKey,
  String canCheck = 'CanInvite',
  String? currentChatId,
  Widget? title,
}) async {
  final selected = await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isDismissible: true,
    builder: (context) => SelectRoomDrawer(
      key: key,
      canCheck: canCheck,
      title: title ?? Text(L10n.of(context).selectChat),
      keyPrefix: 'select-chat',
      roomType: RoomType.groupChat,
    ),
  );
  if (selected == null) {
    // in case of being dismissed, we return the previously selected item
    return currentChatId;
  }
  if (selected == '') {
    // in case of being cleared, we return null
    return null;
  }
  return selected;
}
