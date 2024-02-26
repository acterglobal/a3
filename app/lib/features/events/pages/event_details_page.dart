import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/skeletons/event_details_skeleton_widget.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::event::details');

class EventDetailPage extends ConsumerStatefulWidget {
  final String calendarId;

  const EventDetailPage({super.key, required this.calendarId});

  @override
  ConsumerState<EventDetailPage> createState() =>
      _EventDetailPageConsumerState();
}

class _EventDetailPageConsumerState extends ConsumerState<EventDetailPage> {
  @override
  Widget build(BuildContext context) {
    final event = ref.watch(calendarEventProvider(widget.calendarId));
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: event.when(
        data: (calendarEvent) {
          return CustomScrollView(
            slivers: [
              _buildEventAppBar(calendarEvent),
              _buildEventBody(calendarEvent),
            ],
          );
        },
        error: (error, stackTrace) => Text('Error loading event due to $error'),
        loading: () => const EventDetailsSkeleton(),
      ),
    );
  }

  Widget _buildEventAppBar(CalendarEvent calendarEvent) {
    return Consumer(
      builder: (context, ref, child) {
        return SliverAppBar(
          expandedHeight: 200.0,
          pinned: true,
          actions: [_buildActionMenu(calendarEvent)],
          flexibleSpace: Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(gradient: primaryGradient),
            child: const FlexibleSpaceBar(
              background: Icon(Atlas.calendar_dots, size: 80),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionMenu(CalendarEvent event) {
    //Get membership details
    final spaceId = event.roomIdStr();
    final membership = ref.watch(roomMembershipProvider(spaceId));

    //Create event actions
    List<PopupMenuEntry> actions = [];

    if (membership.valueOrNull != null) {
      final member = membership.requireValue!;

      //Edit Event Action
      if (member.canString('CanPostEvent')) {
        actions.add(
          PopupMenuItem(
            onTap: () => context.pushNamed(
              Routes.editCalendarEvent.name,
              pathParameters: {'calendarId': widget.calendarId},
            ),
            child: const Row(
              children: <Widget>[
                Icon(Atlas.pencil_edit_thin),
                SizedBox(width: 10),
                Text('Edit Event'),
              ],
            ),
          ),
        );
      }

      //Delete Event Action
      if (member.canString('CanRedactOwn') &&
          member.userId().toString() == event.sender().toString()) {
        final roomId = event.roomIdStr();
        actions.addAll([
          PopupMenuItem(
            onTap: () => showAdaptiveDialog(
              context: context,
              builder: (context) => RedactContentWidget(
                title: 'Remove this post',
                eventId: event.eventId().toString(),
                onSuccess: () {
                  ref.invalidate(calendarEventProvider);
                  if (context.mounted) {
                    context.goNamed(
                      Routes.spaceEvents.name,
                      pathParameters: {'spaceId': roomId},
                    );
                  }
                },
                senderId: event.sender().toString(),
                roomId: roomId,
                isSpace: true,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Atlas.trash_can_thin,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                const Text('Remove Event'),
              ],
            ),
          ),
        ]);
      }
    }

    //Report Event Action
    actions.add(
      PopupMenuItem(
        onTap: () => showAdaptiveDialog(
          context: context,
          builder: (ctx) => ReportContentWidget(
            title: 'Report this Event',
            description:
                'Report this content to your homeserver administrator. Please note that your administrator won\'t be able to read or view files in encrypted spaces.',
            eventId: widget.calendarId,
            roomId: event.roomIdStr(),
            senderId: event.sender().toString(),
            isSpace: true,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Atlas.warning_thin,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            const Text('Report Event'),
          ],
        ),
      ),
    );

    return PopupMenuButton(
      itemBuilder: (ctx) => actions,
    );
  }

  Widget _buildEventBody(CalendarEvent calendarEvent) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        key: Key(widget.calendarId),
        children: [
          const SizedBox(height: 20),
          _buildEventBasicDetails(calendarEvent),
          const SizedBox(height: 10),
          _buildEventRsvpActions(),
          const SizedBox(height: 10),
          _buildEventDataSet(calendarEvent),
          const SizedBox(height: 10),
          _buildEventDescription(calendarEvent),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEventBasicDetails(CalendarEvent calendarEvent) {
    final month = getMonthFromDate(calendarEvent.utcStart());
    final day = getDayFromDate(calendarEvent.utcStart());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Month
          Column(
            children: [
              Text(month, style: Theme.of(context).textTheme.titleLarge!),
              Text(day, style: Theme.of(context).textTheme.displayLarge),
            ],
          ),
          // Space
          const SizedBox(width: 30),
          // Title, Space, User counts, comments counts and like counts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calendarEvent.title(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SpaceChip(spaceId: calendarEvent.roomIdStr()),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onRsvp(
    BuildContext context,
    RsvpStatusTag status,
    WidgetRef ref,
  ) async {
    try {
      EasyLoading.show(status: 'Updating RSVP', dismissOnTap: false);
      final event =
          await ref.read(calendarEventProvider(widget.calendarId).future);
      final rsvpManager = await event.rsvpManager();
      final draft = rsvpManager.rsvpDraft();
      draft.status(status.toString());
      final rsvpId = await draft.send();
      _log.info('new rsvp id: $rsvpId');
    } catch (e, s) {
      _log.severe('Error =>', e, s);
    } finally {
      EasyLoading.dismiss();
    }
  }

  Widget _buildEventRsvpActions() {
    final myRsvpStatus = ref.watch(myRsvpStatusProvider(widget.calendarId));
    Set<RsvpStatusTag?> rsvp = <RsvpStatusTag?>{null};
    myRsvpStatus.maybeWhen(
      data: (data) {
        final status = data.statusStr();
        if (status != null) {
          switch (status) {
            case 'yes':
              rsvp = <RsvpStatusTag?>{RsvpStatusTag.Yes};
              break;
            case 'maybe':
              rsvp = <RsvpStatusTag?>{RsvpStatusTag.Maybe};
              break;
            case 'no':
              rsvp = <RsvpStatusTag?>{RsvpStatusTag.No};
              break;
          }
        }
      },
      orElse: () => null,
    );

    return Container(
      color: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        children: [
          _buildEventRsvpActionItem(
            onTap: () => onRsvp(context, RsvpStatusTag.Yes, ref),
            iconData: Icons.check,
            actionName: 'Going',
            isSelected: rsvp.single == RsvpStatusTag.Yes,
          ),
          _buildVerticalDivider(),
          _buildEventRsvpActionItem(
            onTap: () => onRsvp(context, RsvpStatusTag.No, ref),
            iconData: Icons.close,
            actionName: 'Not Going',
            isSelected: rsvp.single == RsvpStatusTag.No,
          ),
          _buildVerticalDivider(),
          _buildEventRsvpActionItem(
            onTap: () => onRsvp(context, RsvpStatusTag.Maybe, ref),
            iconData: Icons.question_mark,
            actionName: 'Maybe',
            isSelected: rsvp.single == RsvpStatusTag.Maybe,
          ),
        ],
      ),
    );
  }

  Widget _buildEventRsvpActionItem({
    required VoidCallback onTap,
    required IconData iconData,
    required String actionName,
    bool isSelected = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(
              iconData,
              size: 26,
              color: isSelected ? Colors.white : Colors.white38,
            ),
            const SizedBox(height: 4),
            Text(
              actionName,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: isSelected ? Colors.white : Colors.white38,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildEventDataSet(CalendarEvent ev) {
    final inDays =
        Jiffy.parseFromDateTime(toDartDatetime(ev.utcStart()).toLocal())
            .endOf(Unit.day)
            .fromNow();
    final startDate =
        Jiffy.parseFromDateTime(toDartDatetime(ev.utcStart()).toLocal())
            .format(pattern: 'EEE, MMM dd AT hh:mm');
    final endDate =
        Jiffy.parseFromDateTime(toDartDatetime(ev.utcEnd()).toLocal())
            .format(pattern: 'EEE, MMM dd AT hh:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Atlas.calendar_dots),
            title: Text(inDays),
            subtitle: Text('$startDate - $endDate'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDescription(CalendarEvent ev) {
    String description = '';
    TextMessageContent? content = ev.description();
    if (content != null && content.body().isNotEmpty) {
      description = content.body();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
