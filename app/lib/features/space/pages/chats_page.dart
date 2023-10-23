import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/features/chat/widgets/create_chat.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class SpaceChatsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceChatsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceIdOrAlias));
    final related = ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: <Widget>[
          related.maybeWhen(
            data: (spaces) {
              bool checkPermission(String permission) {
                if (spaces.membership != null) {
                  return spaces.membership!.canString(permission);
                }
                return false;
              }

              if (!checkPermission('CanLinkSpaces')) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () async {
                        isDesktop || size.width > 600
                            ? await showAdaptiveDialog(
                                barrierDismissible: false,
                                context: shellNavKey.currentContext!,
                                builder: (ctx) => CreateChatPage(
                                  initialSelectedSpaceId: spaceIdOrAlias,
                                  initialPage: 1,
                                ),
                              )
                            : await showModalBottomSheet(
                                isScrollControlled: true,
                                context: shellNavKey.currentContext!,
                                builder: (ctx) => CreateChatPage(
                                  initialSelectedSpaceId: spaceIdOrAlias,
                                  initialPage: 1,
                                ),
                              );
                      },
                      icon: const Icon(Atlas.plus_circle_thin),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          chats.when(
            data: (rooms) {
              if (rooms.isNotEmpty) {
                return SliverAnimatedList(
                  initialItemCount: rooms.length,
                  itemBuilder: (context, index, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: ConvoCard(
                      room: rooms[index],
                      showParent: false,

                      /// FIXME: push is broken for switching from subshell to subshell
                      /// hence we are using `go` here.
                      /// https://github.com/flutter/flutter/issues/125752
                      onTap: () => context.goNamed(
                        Routes.chatroom.name,
                        pathParameters: {'roomId': rooms[index].getRoomIdStr()},
                      ),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(
                child: Center(
                  heightFactor: 5,
                  child: Text('Chats are empty'),
                ),
              );
            },
            error: (error, stackTrace) => SliverToBoxAdapter(
              child: Center(child: Text('Failed to load events due to $error')),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          related.when(
            // FIXME: filter these for entries we are already members of
            data: (spaces) =>
                RiverPagedBuilder<Next?, SpaceHierarchyRoomInfo>.autoDispose(
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
            loading: () =>
                const SliverToBoxAdapter(child: Text('loading other chats')),
          ),
        ],
      ),
    );
  }
}
