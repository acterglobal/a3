import 'dart:math';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/presentation/providers/providers.dart';
import 'package:acter/features/events/presentation/widgets/events_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceEventsPage extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpaceEventsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceEvents = ref.watch(spaceEventsProvider(spaceIdOrAlias));
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
                childAspectRatio: 4.0,
              ),
              itemBuilder: (context, index) => EventItem(event: events[index]),
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
    );
  }
}
