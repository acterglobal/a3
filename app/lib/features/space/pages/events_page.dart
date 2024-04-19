import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/skeletons/event_list_skeleton_widget.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceEventsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceEventsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceEvents = ref.watch(spaceEventsProvider(spaceIdOrAlias));
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: primaryGradient),
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
                    L10n.of(context).events,
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
                  (MediaQuery.of(context).size.width ~/ 300).toInt();
              const int minCount = 3;
              if (events.isEmpty) {
                final membership =
                    ref.watch(roomMembershipProvider(spaceIdOrAlias));
                bool canCreateEvent =
                    membership.requireValue!.canString('CanPostEvent');
                return SliverToBoxAdapter(
                  child: Center(
                    heightFactor: 1,
                    child: EmptyState(
                      title: L10n.of(context).noEventsPlannedYet,
                      subtitle:
                          L10n.of(context).createEventAndBringYourCommunity,
                      image: 'assets/images/empty_event.svg',
                      primaryButton: canCreateEvent
                          ? ActerPrimaryActionButton(
                              onPressed: () => context.pushNamed(
                                Routes.createEvent.name,
                                queryParameters: {'spaceId': spaceIdOrAlias},
                              ),
                              child: Text(L10n.of(context).eventCreate),
                            )
                          : null,
                    ),
                  ),
                );
              }
              return SliverGrid.builder(
                itemCount: events.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: max(1, min(widthCount, minCount)),
                  childAspectRatio: 4.0,
                  mainAxisExtent: 120,
                ),
                itemBuilder: (context, index) =>
                    EventItem(event: events[index]),
              );
            },
            error: (error, stackTrace) => SliverToBoxAdapter(
              child: Center(
                child: Text(L10n.of(context).failedToLoadEventsDueTo(error)),
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
