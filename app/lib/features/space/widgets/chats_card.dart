import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/controllers/client_controller.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:acter/common/controllers/chats_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:core';

final relatedChatsProvider =
    FutureProvider.family<List<Conversation>, String>((ref, spaceId) async {
  final client = ref.watch(clientProvider)!;
  final relatedSpaces = ref.watch(spaceRelationsProvider(spaceId)).requireValue;
  final chats = [];
  for (final related in relatedSpaces.children()) {
    if (related.targetType().tag == RelationTargetTypeTag.ChatRoom) {
      final roomId = related.roomId().toString();
      final room = await client.conversation(related.roomId().toString());
      if (room == null) {
        print('Related room unknown');
      } else {
        chats.add(room);
      }
    }
  }
  return List<Conversation>.from(chats);
});

class ChatsCard extends ConsumerWidget {
  final String spaceId;
  const ChatsCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceId));

    return Card(
      elevation: 0,
      child: Column(
        children: [
          const ListTile(title: Text('Chats')),
          ...chats.when(
            data: (chats) => chats.map(
              (chat) {
                final roomId = chat.getRoomId();
                final profile = ref.watch(chatProfileDataProvider(chat));
                return OutlinedButton(
                  onPressed: () {
                    context.go('/chat/$roomId');
                  },
                  child: profile.when(
                    data: (profile) => ListTile(
                      title: Text(profile.displayName),
                      leading: profile.avatar != null
                          ? CircleAvatar(
                              foregroundImage: MemoryImage(
                                profile.avatar!,
                              ),
                              radius: 24,
                            )
                          : SvgPicture.asset(
                              'assets/icon/acter.svg',
                              height: 24,
                              width: 24,
                            ),
                    ),
                    error: (error, stack) => ListTile(
                      title: Text('Error loading: $roomId'),
                      subtitle: Text('$error'),
                    ),
                    loading: () => ListTile(
                      title: Text(roomId),
                      subtitle: const Text('loading'),
                    ),
                  ),
                );
              },
            ),
            error: (error, stack) => [Text('Loading chats failed: $error')],
            loading: () => [const Text('Loading')],
          )
        ],
      ),
    );
  }
}
