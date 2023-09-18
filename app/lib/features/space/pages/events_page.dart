import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/events_provider.dart';
import 'package:acter/features/events/widgets/events_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceEventsPage extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpaceEventsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceIdOrAlias)).requireValue;
    final spaceEvents = ref.watch(spaceEventsProvider(space));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  'Events',
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
                    Routes.createEvent.name,
                    queryParameters: {'spaceId': spaceIdOrAlias},
                  ),
                ),
              ],
            ),
          ),
          spaceEvents.when(
            data: (events) {
              final widthCount =
                  (MediaQuery.of(context).size.width ~/ 600).toInt();
              const int minCount = 2;
              if (events.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Currently there are no events planned for this space',
                    ),
                  ),
                );
              }
              return SliverGrid.builder(
                itemCount: events.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: max(1, min(widthCount, minCount)),
                  childAspectRatio: 8,
                ),
                itemBuilder: (context, index) =>
                    EventItem(event: events[index]),
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
