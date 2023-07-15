import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/widgets/convo_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceChatsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceChatsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceIdOrAlias));
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
                    child: ConvoCard(room: rooms[index]),
                  ),
                );
              }
              return const SliverToBoxAdapter(
                child: Center(
                  child: Text('There are no chats related to this space'),
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
        ],
      ),
    );
  }
}
