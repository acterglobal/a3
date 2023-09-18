import 'dart:core';
import 'dart:math';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/events/widgets/events_item.dart';
import 'package:acter/features/home/providers/events.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:go_router/go_router.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final account = ref.watch(accountProfileProvider);
    final events = ref.watch(myEventsProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: CustomScrollView(
          slivers: <Widget>[
            PageHeaderWidget(
              title: 'Events',
              sectionColor: Colors.blue.shade200,
              actions: [
                IconButton(
                  icon: const Icon(Atlas.funnel_sort_thin),
                  onPressed: () {
                    customMsgSnackbar(
                      context,
                      'Events filtering not yet implemented',
                    );
                  },
                ),
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
              expandedContent: const Text(
                'Calendar events from all the Spaces you are part of',
              ),
            ),
            events.when(
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
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                    crossAxisCount: max(1, min(widthCount, minCount)),
                    height: MediaQuery.of(context).size.height * 0.1,
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
      ),
    );
  }
}
