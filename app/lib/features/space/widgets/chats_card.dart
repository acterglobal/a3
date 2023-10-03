import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatsCard extends ConsumerWidget {
  final String spaceId;

  const ChatsCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceId));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chats',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          chats.when(
            error: (error, stack) => Text('Loading chats failed: $error'),
            loading: () => const Text('Loading'),
            data: (chats) {
              if (chats.isEmpty) {
                return Text(
                  'There are no chats in this space',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: min(chats.length, 3),
                    itemBuilder: (context, index) => ConvoCard(
                      room: chats[index],
                      showParent: false,
                      onTap: () => context.pushNamed(
                        Routes.chatroom.name,
                        pathParameters: {
                          'roomId': chats[index].getRoomIdStr(),
                        },
                      ),
                    ),
                  ),
                  chats.length > 3
                      ? Padding(
                          padding: const EdgeInsets.only(left: 30, top: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              context.pushNamed(
                                Routes.spaceChats.name,
                                pathParameters: {'spaceId': spaceId},
                              );
                            },
                            child: Text('see all my ${chats.length} chats'),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
