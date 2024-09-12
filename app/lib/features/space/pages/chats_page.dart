import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/loading_convo_card.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/space/widgets/related/chats_helpers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceChatsPage extends ConsumerWidget {
  static const createChatKey = Key('space-chat-create');
  static const actionsMenuKey = Key('space-chat-actions-menu');
  final String spaceIdOrAlias;

  const SpaceChatsPage({super.key, required this.spaceIdOrAlias});

  Widget _renderLoading(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, idx) => const LoadingConvoCard(roomId: 'fake'),
    );
  }

  Widget _renderEmpty(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(spaceIdOrAlias));
    bool canCreateSpace =
        membership.valueOrNull?.canString('CanLinkSpaces') == true;

    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: L10n.of(context).noChatsInThisSpaceYet,
        subtitle: L10n.of(context).getConversationGoingToStart,
        image: 'assets/images/empty_chat.svg',
        primaryButton: canCreateSpace
            ? ActerPrimaryActionButton(
                onPressed: () => context.pushNamed(
                  Routes.createChat.name,
                  queryParameters: {'spaceId': spaceIdOrAlias},
                  extra: 1,
                ),
                child: Text(L10n.of(context).createSpaceChat),
              )
            : null,
        secondaryButton: canCreateSpace
            ? ActerInlineTextButton(
                onPressed: () => context.pushNamed(
                  Routes.linkChat.name,
                  pathParameters: {'spaceId': spaceIdOrAlias},
                ),
                child: Text(L10n.of(context).linkToChat),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceName =
        ref.watch(roomDisplayNameProvider(spaceIdOrAlias)).valueOrNull ??
            spaceIdOrAlias;

    final chatListAsync =
        ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    final chatList = chatListAsync.valueOrNull?.knownChats ?? [];
    final remoteChatsAsync =
        ref.watch(remoteChatRelationsProvider(spaceIdOrAlias));
    final remoteChats = remoteChatsAsync.valueOrNull ?? [];
    final isLoading = chatListAsync.isLoading || remoteChatsAsync.isLoading;
    final isEmpty = (chatListAsync.hasValue ? chatList.isEmpty : false) &&
        (remoteChatsAsync.hasValue ? remoteChats.isEmpty : false);

    final membership = ref.watch(roomMembershipProvider(spaceIdOrAlias));
    bool canCreateSpace =
        membership.valueOrNull?.canString('CanLinkSpaces') == true;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.of(context).chat),
            Text(
              '($spaceName)',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Atlas.arrows_rotating_right_thin),
            iconSize: 28,
            color: Theme.of(context).colorScheme.surface,
            onPressed: () async {
              ref.invalidate(spaceRelationsProvider);
            },
          ),
          if (canCreateSpace)
            PopupMenuButton(
              key: actionsMenuKey,
              icon: const Icon(Atlas.plus_circle),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                PopupMenuItem(
                  key: createChatKey,
                  onTap: () => context.pushNamed(
                    Routes.createChat.name,
                    queryParameters: {'spaceId': spaceIdOrAlias},
                    extra: 1,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(L10n.of(context).createChat),
                      const Spacer(),
                      const Icon(Atlas.chats),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () => context.pushNamed(
                    Routes.linkChat.name,
                    pathParameters: {'spaceId': spaceIdOrAlias},
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(L10n.of(context).linkExistingChat),
                      const Spacer(),
                      const Icon(Atlas.chats),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (chatList.isNotEmpty)
              chatsListUI(
                ref,
                spaceIdOrAlias,
                chatList,
                chatList.length,
                showOptions: true,
              ),
            if (isLoading) _renderLoading(context),
            if (remoteChats.isNotEmpty)
              renderFurther(context, ref, spaceIdOrAlias, null),
            if (isEmpty) _renderEmpty(context, ref),
          ],
        ),
      ),
    );
  }
}
