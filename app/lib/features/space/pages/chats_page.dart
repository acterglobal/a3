import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: <Widget>[
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
                      onTap: () => context.pushNamed(
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
