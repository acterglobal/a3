import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/controllers/client_controller.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:core';

final relatedChatsProvider =
    FutureProvider.family<List<Conversation>, String>((ref, spaceId) async {
  final client = ref.watch(clientProvider)!;
  final relatedSpaces = ref.watch(spaceRelationsProvider(spaceId)).requireValue;
  final chats = [];
  for (final related in relatedSpaces.children()) {
    if (related.targetType().tag == RelationTargetTypeTag.ChatRoom) {
      final roomId = related.roomId().toString();
      print("Loading $roomId");
      final room = await client.conversation(related.roomId().toString());
      print("Conversation found.");
      if (room == null) {
        print("Related room unknown");
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
                return OutlinedButton(
                  onPressed: () {
                    context.go('/chat/$roomId');
                  },
                  child: Text(chat.getRoomId()),
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
