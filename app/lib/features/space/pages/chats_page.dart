import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:acter/common/widgets/default_button.dart';

import 'package:acter/common/providers/room_providers.dart';

class SpaceChatsPage extends ConsumerWidget {
  static const createChatKey = Key('space-chat-create');
  static const actionsMenuKey = Key('space-chat-actions-menu');
  final String spaceIdOrAlias;

  const SpaceChatsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceIdOrAlias));
    final related = ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    final dataCheck = chats.asData != null && related.asData != null;
    final membership = ref.watch(roomMembershipProvider(spaceIdOrAlias));
    bool canCreateSpace = membership.requireValue!.canString('CanLinkSpaces');

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
          ),
          dataCheck
              ? SliverMainAxisGroup(
                  slivers: <Widget>[
                    related.maybeWhen(
                      data: (spaces) {
                        bool checkPermission(String permission) {
                          if (spaces.membership != null) {
                            return spaces.membership!.canString(permission);
                          }
                          return false;
                        }

                        final canLinkSpace = checkPermission('CanLinkSpaces');

                        if (!canLinkSpace) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
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
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry>[
                                  PopupMenuItem(
                                    key: createChatKey,
                                    onTap: () => context.pushNamed(
                                      Routes.createChat.name,
                                      queryParameters: {
                                        'spaceId': spaceIdOrAlias,
                                      },
                                      extra: 1,
                                    ),
                                    child: const Row(
                                      children: <Widget>[
                                        Text('Create Chat'),
                                        Spacer(),
                                        Icon(Atlas.chats),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    onTap: () => context.pushNamed(
                                      Routes.linkChat.name,
                                      pathParameters: {
                                        'spaceId': spaceIdOrAlias,
                                      },
                                    ),
                                    child: const Row(
                                      children: <Widget>[
                                        Text('Link existing Chat'),
                                        Spacer(),
                                        Icon(Atlas.chats),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      orElse: () =>
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                    ),
                    chats.when(
                      data: (rooms) {
                        if (rooms.isNotEmpty) {
                          return SliverAnimatedList(
                            initialItemCount: rooms.length,
                            itemBuilder: (context, index, animation) =>
                                SizeTransition(
                              sizeFactor: animation,
                              child: ConvoCard(
                                room: rooms[index],
                                showParent: false,
                                onTap: () => context.goNamed(
                                  Routes.chatroom.name,
                                  pathParameters: {
                                    'roomId': rooms[index].getRoomIdStr(),
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverToBoxAdapter(
                          child: Container(),
                        );
                      },
                      error: (error, stackTrace) => SliverToBoxAdapter(
                        child: Center(
                          child: Text('Failed to load events due to $error'),
                        ),
                      ),
                      loading: () => const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    related.when(
                      // FIXME: filter these for entries we are already members of
                      data: (spaces) => RiverPagedBuilder<Next?,
                          SpaceHierarchyRoomInfo>.autoDispose(
                        firstPageKey: const Next(isStart: true),
                        provider: remoteChatHierarchyProvider(spaces),
                        itemBuilder: (context, item, index) =>
                            ConvoHierarchyCard(space: item),
                        noItemsFoundIndicatorBuilder: (context, controller) =>
                            const SizedBox.shrink(),
                        pagedBuilder: (controller, builder) => PagedSliverList(
                          pagingController: controller,
                          builderDelegate: builder,
                        ),
                      ),
                      error: (e, s) => SliverToBoxAdapter(
                        child: Text('Error loading related chats: $e'),
                      ),
                      loading: () => const SliverToBoxAdapter(
                        child: Text('loading other chats'),
                      ),
                    ),
                  ],
                )
              : SliverToBoxAdapter(
                  child: Center(
                    heightFactor: 1,
                    child: EmptyState(
                      title: 'No chats in this space yet',
                      subtitle:
                          'Get the conversation going to start organizing collaborating',
                      image: 'assets/images/empty_chat.svg',
                      primaryButton: canCreateSpace
                          ? DefaultButton(
                              onPressed: () => context.pushNamed(
                                Routes.createChat.name,
                                queryParameters: {'spaceId': spaceIdOrAlias},
                                extra: 1,
                              ),
                              title: 'Create Space Chat',
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.success,
                                disabledBackgroundColor: Theme.of(context)
                                    .colorScheme
                                    .success
                                    .withOpacity(0.5),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
