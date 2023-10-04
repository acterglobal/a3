import 'dart:core';
import 'dart:math';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/events/presentation/providers/providers.dart';
import 'package:acter/features/events/presentation/widgets/events_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:go_router/go_router.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingEventsProvider);
    final past = ref.watch(pastEventsProvider);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Events',
            sectionDecoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Atlas.plus_circle_thin,
                  color: Theme.of(context).colorScheme.neutral5,
                ),
                iconSize: 28,
                color: Theme.of(context).colorScheme.surface,
                onPressed: () => context.pushNamed(Routes.createEvent.name),
              ),
            ],
            expandedContent: size.width <= 600
                ? null
                : Text(
                    'Calendar events from all the Spaces you are part of',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Upcoming',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          upcoming.when(
            data: (events) {
              final widthCount =
                  (MediaQuery.of(context).size.width ~/ 600).toInt();
              const int minCount = 2;
              if (events.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text('There\'s nothing scheduled yet'),
                  ),
                );
              }
              return SliverGrid.builder(
                itemCount: events.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: max(1, min(widthCount, minCount)),
                  childAspectRatio: 4,
                ),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventItem(
                    event: event,
                  );
                },
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text('Loading failed: $error'),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Text('Loading'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Past',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          past.when(
            data: (events) {
              final widthCount =
                  (MediaQuery.of(context).size.width ~/ 600).toInt();
              const int minCount = 2;
              if (events.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text('There\'s nothing scheduled yet'),
                  ),
                );
              }
              return SliverGrid.builder(
                itemCount: events.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: max(1, min(widthCount, minCount)),
                  childAspectRatio: 4,
                ),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventItem(
                    event: event,
                  );
                },
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text('Loading failed: $error'),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Text('Loading'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
