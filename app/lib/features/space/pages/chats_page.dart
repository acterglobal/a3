import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:acter/features/space/providers/space_providers.dart';
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
    final related = ref.watch(spaceRelationsProvider(spaceIdOrAlias));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  'Chats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Atlas.plus_circle_thin,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.surface,
                  onPressed: () => context.pushNamed(
                    Routes.createChat.name,
                    queryParameters: {'spaceId': spaceIdOrAlias},
                  ),
                ),
              ],
            ),
          ),
          chats.when(
            data: (rooms) {
              if (rooms.isNotEmpty) {
                return SliverAnimatedList(
                  initialItemCount: rooms.length,
                  itemBuilder: (context, index, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: ConvoCard(room: rooms[index], showParent: false),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
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
              provider: chatHierarchyProvider(spaces),
              itemBuilder: (context, item, index) =>
                  ConvoHierarchyCard(space: item),
              noItemsFoundIndicatorBuilder: (context, controller) =>
                  const SizedBox.shrink(),
              pagedBuilder: (controller, builder) => PagedSliverList(
                pagingController: controller,
                builderDelegate: builder,
              ),
            ),
            error: (e, s) => Text('Error loading related spaces: $e'),
            loading: () => const Text('loading other chats'),
          ),
        ],
      ),
    );
  }
}
