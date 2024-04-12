import 'dart:math';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/skeletons/event_list_skeleton_widget.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(myUpcomingEventsProvider);
    final past = ref.watch(myPastEventsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: L10n.of(context).events,
            sectionDecoration: const BoxDecoration(
              gradient: primaryGradient,
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
            expandedContent: Text(
              L10n.of(context).calendarEventsFromAllTheSpaces,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            sliver: SliverToBoxAdapter(
              child: Text(
                L10n.of(context).upcoming,
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
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(L10n.of(context).thereIsNothingScheduledYet),
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
                child: Text(L10n.of(context).loadingFailed(error)),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: EventListSkeleton()),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            sliver: SliverToBoxAdapter(
              child: Text(
                L10n.of(context).past,
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
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(L10n.of(context).thereIsNothingScheduledYet),
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
                child: Text(L10n.of(context).loadingFailed(error)),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: EventListSkeleton()),
            ),
          ),
        ],
      ),
    );
  }
}
