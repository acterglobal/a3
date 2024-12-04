import 'package:acter/common/toolkit/errors/error_page.dart';
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
  final ProviderBase<AsyncValue<List<CalendarEvent>>> listProvider;
  final int? limit;
  final bool showSectionHeader;
  final VoidCallback? onClickSectionHeader;
  final String? sectionHeaderTitle;
  final bool? isShowSeeAllButton;
  final bool showSectionBg;
  final Function(String)? onTapEventItem;
  final bool shrinkWrap;
  final bool isShowSpaceName;
  final Widget Function()? emptyStateBuilder;

  const EventListWidget({
    super.key,
    this.limit,
    this.isShowSpaceName = true,
    required this.listProvider,
    this.showSectionHeader = false,
    this.onClickSectionHeader,
    this.sectionHeaderTitle,
    this.isShowSeeAllButton,
    this.showSectionBg = true,
    this.onTapEventItem,
    this.shrinkWrap = true,
    this.emptyStateBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calEventsLoader = ref.watch(listProvider);

    return calEventsLoader.when(
      data: (eventList) => buildEventSectionUI(context, eventList),
      error: (error, stack) => eventListErrorWidget(context, ref, error, stack),
      loading: () => const EventListSkeleton(),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
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
      textBuilder: (error, code) => L10n.of(context).loadingFailed(error),
      onRetryTap: () {
        ref.invalidate(listProvider);
      },
    );
  }

  Widget buildEventSectionUI(
    BuildContext context,
    List<CalendarEvent> eventList,
  ) {
    if (eventList.isEmpty) {
      return (emptyStateBuilder ?? () => const SizedBox.shrink())();
    }

    final count = (limit ?? eventList.length).clamp(0, eventList.length);
    return showSectionHeader
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionHeader(
                title: sectionHeaderTitle ?? L10n.of(context).events,
                isShowSeeAllButton:
                    isShowSeeAllButton ?? count < eventList.length,
                showSectionBg: showSectionBg,
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
          isShowSpaceName: isShowSpaceName,
          onTapEventItem: onTapEventItem,
        );
      },
    );
  }
}
