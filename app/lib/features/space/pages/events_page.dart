import 'dart:math';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/events_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/space/widgets/space_header.dart';

import '../../../common/widgets/default_button.dart';
import '../../../common/widgets/error_widget.dart';

class SpaceEventsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceEventsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceEvents = ref.watch(spaceEventsProvider(spaceIdOrAlias));
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
          ),
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
                  AddButtonWithCanPermission(
                    roomId: spaceIdOrAlias,
                    canString: 'CanPostEvent',
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
                return SliverToBoxAdapter(
                  child: Center(
                    heightFactor: 1,
                    child: ErrorWidgetTemplate(
                      title: 'No events planned yet',
                      subtitle:
                          'Create new event and bring your community together',
                      image: 'assets/images/empty_events.png',
                      button: DefaultButton(
                        onPressed: () {},
                        title: 'Create Event',
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.success,
                          disabledBackgroundColor: Theme.of(context)
                              .colorScheme
                              .success
                              .withOpacity(0.5),
                        ),
                      ),
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
                itemBuilder: (context, index) =>
                    EventItem(event: events[index]),
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
        ],
      ),
    );
  }
}
