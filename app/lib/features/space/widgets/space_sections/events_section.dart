import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::sections::cal_events');

class EventsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const EventsSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calEventsLoader = ref.watch(
      eventListSearchFilterProvider((spaceId: spaceId, searchText: '')),
    );
    return calEventsLoader.when(
      data: (calEvents) => buildEventsSectionUI(context, calEvents),
      error: (e, s) {
        _log.severe('Failed to search cal events in space', e, s);
        return Center(
          child: Text(L10n.of(context).searchingFailed(e)),
        );
      },
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildEventsSectionUI(
    BuildContext context,
    List<CalendarEvent> events,
  ) {
    int eventsLimit = (events.length > limit) ? limit : events.length;
    bool isShowSeeAllButton = events.length > eventsLimit;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).events,
          isShowSeeAllButton: isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceEvents.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        eventsListUI(events, eventsLimit),
      ],
    );
  }

  Widget eventsListUI(List<CalendarEvent> events, int eventsLimit) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: eventsLimit,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return EventItem(event: events[index]);
      },
    );
  }
}
