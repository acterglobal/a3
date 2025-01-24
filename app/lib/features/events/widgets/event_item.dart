import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/blinking_text.dart';
import 'package:acter/common/widgets/reference_details_item.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter/features/events/widgets/event_date_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent, RefDetails, RsvpStatusTag;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::cal_event::event_item');

class EventItem extends ConsumerWidget {
  static const eventItemClick = Key('event_item_click');

  final String eventId;
  final RefDetails? refDetails;
  final EdgeInsetsGeometry? margin;
  final Function(String)? onTapEventItem;
  final bool isShowRsvp;
  final bool isShowSpaceName;

  const EventItem({
    super.key,
    required this.eventId,
    this.refDetails,
    this.margin,
    this.onTapEventItem,
    this.isShowRsvp = true,
    this.isShowSpaceName = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(calendarEventProvider(eventId)).valueOrNull;
    if (event != null) {
      return _buildEventItemUI(context, ref, event);
    } else if (refDetails != null) {
      return ReferenceDetailsItem(refDetails: refDetails!);
    } else {
      return const Skeletonizer(child: SizedBox(height: 100, width: 100));
    }
  }

  Widget _buildEventItemUI(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) {
    final eventType = ref.watch(eventTypeProvider(event));
    final isBookmarked = ref.watch(isBookmarkedProvider(BookmarkType.forEvent(eventId)));
    return InkWell(
      key: eventItemClick,
      onTap: () {
        final eventId = event.eventId().toString();
        onTapEventItem.map(
          (cb) => cb(eventId),
          orElse: () => context.pushNamed(
            Routes.calendarEvent.name,
            pathParameters: {'calendarId': eventId},
          ),
        );
      },
      child: Stack(
        children: [
          buildEventItemView(context, ref, event, eventType),
          if (isBookmarked)
            buildEventBookmarkView(context),
        ],
      ),
    );
  }

  Widget buildEventItemView(BuildContext context, WidgetRef ref, CalendarEvent event, EventFilters eventType) {
    return Card(
      margin: margin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          EventDateWidget(
            calendarEvent: event,
            eventType: eventType,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventTitle(context, event.title()),
                _buildEventSubtitle(context, ref, event),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (eventType == EventFilters.ongoing)
            _buildHappeningIndication(context),
          const SizedBox(width: 10),
          if (isShowRsvp) _buildRsvpStatus(context, ref, event),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget buildEventBookmarkView(BuildContext context) {
    return Positioned(
      right: 45,
      top: 5,
      child: Icon(
        Icons.bookmark_sharp,
        color: Theme.of(context).unselectedWidgetColor,
        size: 24,
      ),
    );
  }

  Widget _buildEventTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventSubtitle(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) {
    String eventSpaceName =
        ref.watch(roomDisplayNameProvider(event.roomIdStr())).valueOrNull ??
            L10n.of(context).unknown;
    String eventDateTime = '${formatDate(event)} (${formatTime(event)})';
    return Text(
      isShowSpaceName ? eventSpaceName : eventDateTime,
      style: Theme.of(context).textTheme.labelLarge,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRsvpStatus(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) {
    final lang = L10n.of(context);
    final eventId = event.eventId().toString();
    final rsvpLoader = ref.watch(myRsvpStatusProvider(eventId));
    return rsvpLoader.when(
      data: (status) {
        final widget = _getRsvpStatus(context, status); // kebab-case
        return widget ?? const SizedBox.shrink();
      },
      error: (e, s) {
        _log.severe('Failed to load RSVP status', e, s);
        return Chip(
          label: Text(
            lang.errorLoadingRsvpStatus(e),
            softWrap: true,
          ),
        );
      },
      loading: () => Chip(
        label: Text(lang.loadingRsvpStatus),
      ),
    );
  }

  Widget? _getRsvpStatus(BuildContext context, RsvpStatusTag? status) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      RsvpStatusTag.Yes => Icon(
          Icons.check_circle,
          color: colorScheme.secondary,
        ),
      RsvpStatusTag.No => Icon(
          Icons.cancel,
          color: colorScheme.error,
        ),
      RsvpStatusTag.Maybe => const Icon(Icons.question_mark_rounded),
      _ => null,
    };
  }

  Widget _buildHappeningIndication(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: BlinkText(
        L10n.of(context).live,
        style: Theme.of(context).textTheme.labelLarge,
        beginColor: Colors.white,
        endColor: colorScheme.secondary,
      ),
    );
  }
}
