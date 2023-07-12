import 'dart:core';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/widgets/conversation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatsCard extends ConsumerWidget {
  final String spaceId;

  const ChatsCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceId));
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: chats.length > 3 ? 3 : chats.length,
                      itemBuilder: (context, index) =>
                          ConversationCard(room: chats[index]),
                    ),
                    chats.length > 3
                        ? Padding(
                            padding: const EdgeInsets.only(left: 30, top: 8),
                            child: OutlinedButton(
                              onPressed: () {
                                context.goNamed(
                                  Routes.spaceChats.name,
                                  pathParameters: {'spaceId': spaceId},
                                );
                              },
                              child:
                                  Text('see all my ${chats.length - 3} chats'),
                            ),
                          )
                        : const SizedBox.shrink()
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
