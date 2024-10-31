import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_list_skeleton_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::event-list-widget');

class EventListWidget extends ConsumerWidget {
  final String? spaceId;
  final String? searchValue;
  final int? limit;
  final bool showSectionHeader;
  final VoidCallback? onClickSectionHeader;
  final bool shrinkWrap;
  final Widget emptyState;

  const EventListWidget({
    super.key,
    this.limit,
    this.spaceId,
    this.searchValue,
    this.showSectionHeader = false,
    this.onClickSectionHeader,
    this.shrinkWrap = true,
    this.emptyState = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calEventsLoader = ref.watch(
      eventListSearchFilterProvider(
        (spaceId: spaceId, searchText: searchValue ?? ''),
      ),
    );

    return calEventsLoader.when(
      data: (eventList) => buildEventSectionUI(context, eventList),
      error: (error, stack) => eventListErrorWidget(context, ref, error, stack),
      loading: () => const EventListSkeleton(),
    );
  }

  Widget eventListErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace stack,
  ) {
    _log.severe('Failed to load events', error, stack);
    return ErrorPage(
      background: const EventListSkeleton(),
      error: error,
      stack: stack,
      textBuilder: L10n.of(context).loadingFailed,
      onRetryTap: () {
        ref.invalidate(
          eventListSearchFilterProvider(
            (spaceId: spaceId, searchText: searchValue ?? ''),
          ),
        );
      },
    );
  }

  Widget buildEventSectionUI(
    BuildContext context,
    List<CalendarEvent> eventList,
  ) {
    if (eventList.isEmpty) return emptyState;

    final count = (limit ?? eventList.length).clamp(0, eventList.length);
    return showSectionHeader
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionHeader(
                title: L10n.of(context).events,
                isShowSeeAllButton: count < eventList.length,
                onTapSeeAll: () => onClickSectionHeader == null
                    ? null
                    : onClickSectionHeader!(),
              ),
              eventListUI(eventList, count),
            ],
          )
        : eventListUI(eventList, count);
  }

  Widget eventListUI(List<CalendarEvent> eventList, int count) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (context, index) {
        return EventItem(
          event: eventList[index],
          isShowSpaceName: spaceId == null,
        );
      },
    );
  }
}
