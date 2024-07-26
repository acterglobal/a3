import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/room/room_hierarchy_options_menu.dart';
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
    final chats = ref
            .watch(spaceRelationsOverviewProvider(spaceIdOrAlias))
            .valueOrNull
            ?.knownChats ??
        [];

    if (chats.isEmpty) {
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

  Widget renderConvoCard(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    bool isSuggested,
  ) {
    return ConvoCard(
      roomId: roomId,
      showParents: false,
      showSuggestedMark: isSuggested,
      onTap: () => goToChat(context, roomId),
      trailing: RoomHierarchyOptionsMenu(
        childId: roomId,
        parentId: spaceIdOrAlias,
        isSuggested: isSuggested,
      ),
    );
  }

  Widget renderChats(BuildContext context, WidgetRef ref) {
    final relations =
        ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias)).valueOrNull;
    final chats = relations?.knownChats ?? [];
    final suggested = relations?.suggestedIds ?? [];

    return SliverAnimatedList(
      initialItemCount: chats.length,
      itemBuilder: (context, index, animation) {
        final roomId = chats[index];
        final isSuggested = suggested.contains(roomId);
        return SizeTransition(
          sizeFactor: animation,
          child: renderConvoCard(context, ref, roomId, isSuggested),
        );
      },
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
              showIconIfSuggested: true,
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
      body: CustomScrollView(
        slivers: <Widget>[
          if (chatsList?.knownChats.isNotEmpty == true)
            renderChats(context, ref),
          if (chatsList?.hasMore == true) renderFurther(context, ref),
          if (chatsList?.hasMore == false &&
              chatsList?.knownChats.isEmpty == true)
            _renderEmpty(context, ref),
        ],
      ),
    );
  }
}
