import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/room/brief_room_list_entry.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';

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
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final spaces = ref.watch(spacesProvider);
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            key: key,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: title ?? const Text('Select Space'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Atlas.minus_circle_thin),
                    onPressed: () {
                      Navigator.pop(context, '');
                    },
                    label: const Text('Clear'),
                  ),
                ],
              ),
              Flexible(
                child: spaces.isEmpty
                    ? const Text('no spaces found')
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: spaces.length,
                        itemBuilder: (context, index) {
                          final space = spaces[index];
                          return BriefRoomEntry(
                            roomId: space.getRoomIdStr(),
                            avatarDisplayMode: DisplayMode.Space,
                            keyPrefix: 'select-space',
                            selectedValue: current,
                            canCheck: canCheck,
                            onSelect: (roomId) {
                              Navigator.pop(context, roomId);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
