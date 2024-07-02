import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/router/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const ChatsSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chatsLabel(context),
        chatsList(context, ref),
      ],
    );
  }

  Widget chatsLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            L10n.of(context).chats,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          ActerInlineTextButton(
            onPressed: () {},
            child: Text(L10n.of(context).seeAll),
          ),
        ],
      ),
    );
  }

  Widget chatsList(BuildContext context, WidgetRef ref) {
    final chatsList = ref.watch(relatedChatsProvider(spaceId));

    return chatsList.when(
      data: (chats) {
        int chatsLimit = (chats.length > limit) ? limit : chats.length;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: chatsLimit,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return ConvoCard(
              room: chats[index],
              showParents: false,
              onTap: () => goToChat(context, chats[index].getRoomIdStr()),
            );
          },
        );
      },
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }
}
