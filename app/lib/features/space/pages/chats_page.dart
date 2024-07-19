import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/router/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceChatsPage extends ConsumerWidget {
  static const createChatKey = Key('space-chat-create');
  static const actionsMenuKey = Key('space-chat-actions-menu');
  final String spaceIdOrAlias;

  const SpaceChatsPage({super.key, required this.spaceIdOrAlias});

  Widget _renderEmpty(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceIdOrAlias));

    if ((chats.valueOrNull?.isNotEmpty ?? true)) {
      // we are still loading or chats has been found locally
      return Container();
    }

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

  Widget renderChats(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceIdOrAlias));

    return chats.when(
      data: (rooms) {
        return SliverAnimatedList(
          initialItemCount: rooms.length,
          itemBuilder: (context, index, animation) => SizeTransition(
            sizeFactor: animation,
            child: ConvoCard(
              room: rooms[index],
              showParents: false,
              onTap: () => goToChat(context, rooms[index].getRoomIdStr()),
            ),
          ),
        );
      },
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: Center(
          child: Text(L10n.of(context).failedToLoadChatsDueTo(error)),
        ),
      ),
      loading: () => SliverToBoxAdapter(
        child: Skeletonizer(
          child: ListTile(
            title: Text(L10n.of(context).roomId),
            subtitle: Text(L10n.of(context).loading),
          ),
        ),
      ),
    );
  }

  Widget renderFurther(BuildContext context, WidgetRef ref) {
    final remoteChats = ref.watch(remoteChatRelationsProvider(spaceIdOrAlias));

    return remoteChats.when(
      data: (chats) {
        if (chats.isEmpty) {
          return const SizedBox.shrink();
        }

        return SliverList.builder(
          itemCount: chats.length,
          itemBuilder: (context, idx) {
            final item = chats[idx];
            return ConvoHierarchyCard(
              parentId: spaceIdOrAlias,
              roomInfo: item,
            );
          },
        );
      },
      error: (e, s) => SliverToBoxAdapter(
        child: Text(L10n.of(context).errorLoadingRelatedChats(e)),
      ),
      loading: () => SliverToBoxAdapter(
        child: Skeletonizer(
          child: Card(
            child: ListTile(
              title: Text(L10n.of(context).loadingOtherChats),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceName =
        ref.watch(roomDisplayNameProvider(spaceIdOrAlias)).valueOrNull ??
            spaceIdOrAlias;

    final chatsList =
        ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias)).valueOrNull;

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
      body: CustomScrollView(
        slivers: <Widget>[
          if (chatsList?.knownChats.isNotEmpty == true)
            renderChats(context, ref),
          if (chatsList?.hasMoreChats == true) renderFurther(context, ref),
          if (chatsList?.hasMoreChats == false &&
              chatsList?.knownChats.isEmpty == true)
            _renderEmpty(context, ref),
        ],
      ),
    );
  }
}
