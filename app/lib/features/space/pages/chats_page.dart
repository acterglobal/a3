import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceChatsPage extends ConsumerWidget {
  static const createChatKey = Key('space-chat-create');
  static const actionsMenuKey = Key('space-chat-actions-menu');
  final String spaceIdOrAlias;

  const SpaceChatsPage({super.key, required this.spaceIdOrAlias});

  Widget renderRelated(BuildContext context, WidgetRef ref) {
    final related = ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    return related.maybeWhen(
      data: (spaces) {
        bool checkPermission(String permission) {
          return spaces.membership?.canString(permission) ?? false;
        }

        final canLinkSpace = checkPermission('CanLinkSpaces');

        if (!canLinkSpace) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton(
                key: actionsMenuKey,
                icon: Icon(
                  Atlas.plus_circle,
                  color: Theme.of(context).colorScheme.neutral5,
                ),
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
        );
      },
      orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _renderEmpty(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceIdOrAlias));

    if ((chats.valueOrNull?.isNotEmpty ?? true)) {
      // we are still loading or chats has been found locally
      return Container();
    }

    final membership = ref.watch(roomMembershipProvider(spaceIdOrAlias));
    bool canCreateSpace = membership.requireValue!.canString('CanLinkSpaces');

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
              showParent: false,
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

  AsyncValue<
      AutoDisposeStateNotifierProvider<FilteredSpaceHierarchyNotifier,
          PagedState<Next?, SpaceHierarchyRoomInfo>>> relatedProvider(
    WidgetRef ref,
  ) {
    return ref
        .watch(spaceRelationsOverviewProvider(spaceIdOrAlias))
        .whenData((spaces) => remoteChatHierarchyProvider(spaces));
  }

  Widget renderFurther(BuildContext context, WidgetRef ref) {
    return relatedProvider(ref).when(
      data: (provider) =>
          RiverPagedBuilder<Next?, SpaceHierarchyRoomInfo>.autoDispose(
        firstPageKey: const Next(isStart: true),
        provider: provider,
        itemBuilder: (context, item, index) => ConvoHierarchyCard(
          parentId: spaceIdOrAlias,
          roomInfo: item,
        ),
        noItemsFoundIndicatorBuilder: (context, controller) =>
            _renderEmpty(context, ref),
        pagedBuilder: (controller, builder) => PagedSliverList(
          pagingController: controller,
          builderDelegate: builder,
        ),
      ),
      error: (e, s) => SliverToBoxAdapter(
        child: Text(L10n.of(context).errorLoadingRelatedChats(e)),
      ),
      loading: () => SliverToBoxAdapter(
        child: Text(L10n.of(context).loadingOtherChats),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: primaryGradient),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
          ),
          renderRelated(context, ref),
          renderChats(context, ref),
          renderFurther(context, ref),
        ],
      ),
    );
  }
}
