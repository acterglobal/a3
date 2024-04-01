import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/room/brief_room_list_entry.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final chats = ref.watch(chatsProvider);
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
                    child: title ?? Text(L10n.of(context).select('chat')),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Atlas.minus_circle_thin),
                    onPressed: () {
                      Navigator.pop(context, '');
                    },
                    label: Text(L10n.of(context).clear),
                  ),
                ],
              ),
              Flexible(
                child: chats.isEmpty
                    ? Text(L10n.of(context).noChatsFound)
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final convo = chats[index];
                          return BriefRoomEntry(
                            roomId: convo.getRoomIdStr(),
                            avatarDisplayMode: DisplayMode.GroupChat,
                            keyPrefix: 'select-chat',
                            selectedValue: currentChatId,
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
    return currentChatId;
  }
  if (selected == '') {
    // in case of being cleared, we return null
    return null;
  }
  return selected;
}
