import 'package:acter/common/widgets/room/select_room_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

const Key selectSpaceDrawerKey = Key('space-widgets-select-space-drawer');

Future<String?> selectSpaceDrawer({
  required BuildContext context,
  Key? key = selectSpaceDrawerKey,
  String canCheck = 'CanLinkSpaces',
  String? currentSpaceId,
  Widget? title,
}) async {
  final selected = await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    builder: (context) => Container(
      constraints: BoxConstraints(maxHeight: 700),
      child: SelectRoomDrawer(
        key: key,
        canCheck: canCheck,
        currentSpaceId: currentSpaceId,
        title: title ?? Text(L10n.of(context).selectSpace),
        keyPrefix: 'select-space',
        roomType: RoomType.space,
      ),
    ),
  );
  if (selected == null) {
    // in case of being dismissed, we return the previously selected item
    return currentSpaceId;
  }
  if (selected == '') {
    // in case of being cleared, we return null
    return null;
  }
  return selected;
}
