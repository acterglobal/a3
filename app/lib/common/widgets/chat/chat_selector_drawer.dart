import 'package:acter/common/widgets/room/select_room_drawer.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

const Key selectChatDrawerKey = Key('chat-widgets-select-chat-drawer');

Future<String?> selectChatDrawer({
  required BuildContext context,
  Key? key = selectChatDrawerKey,
  RoomCanCheck? canCheck,
  String? currentChatId,
  Widget? title,
}) async {
  final selected = await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isDismissible: true,
    builder:
        (context) => SelectRoomDrawer(
          key: key,
          title: title ?? Text(L10n.of(context).selectChat),
          keyPrefix: 'select-chat',
          roomType: RoomType.groupChat,
          canCheck: canCheck,
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
