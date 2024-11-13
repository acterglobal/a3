import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_list_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyEventsSection extends ConsumerWidget {
  final int? limit;
  final EventFilters eventFilters;

  const MyEventsSection({
    super.key,
    this.limit,
    this.eventFilters = EventFilters.upcoming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    //Event Provider
    final eventListProvider = switch (eventFilters) {
      EventFilters.ongoing => myOngoingEventListProvider(null),
      _ => myUpcomingEventListProvider(null),
    };
    //Section Title Data
    final sectionTitle = switch (eventFilters) {
      EventFilters.ongoing => lang.happeningNow,
      _ => lang.myUpcomingEvents,
    };

    return EventListWidget(
      showSectionHeader: true,
      sectionHeaderTitle: sectionTitle,
      showSectionBg: false,
      isShowSeeAllButton: true,
      limit: limit,
      listProvider: eventListProvider,
      onClickSectionHeader: () => context.pushNamed(Routes.calendarEvents.name),
    );
  }
}
