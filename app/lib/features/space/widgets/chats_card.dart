import 'dart:math';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/router/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
            L10n.of(context).chats,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          chats.when(
            error: (error, stack) => Text(
              L10n.of(context).loadingChatsFailed(error),
            ),
            loading: () => Text(L10n.of(context).loading),
            data: (chats) {
              if (chats.isEmpty) {
                return Text(
                  L10n.of(context).thereAreNoChatsInThisSpace,
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
                      onTap: () =>
                          goToChat(context, chats[index].getRoomIdStr()),
                    ),
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
                            child: Text(
                              L10n.of(context).seeAllMyChats(chats.length),
                            ),
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
