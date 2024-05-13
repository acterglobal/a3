import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/participants_list.dart';
import 'package:acter/features/events/widgets/skeletons/event_details_skeleton_widget.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/space/widgets/member_avatar.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger('a3::event::details');

class EventDetailPage extends ConsumerStatefulWidget {
  final String calendarId;

  const EventDetailPage({super.key, required this.calendarId});

  @override
  ConsumerState<EventDetailPage> createState() =>
      _EventDetailPageConsumerState();
}

class _EventDetailPageConsumerState extends ConsumerState<EventDetailPage> {
  ValueNotifier<List<String>> eventParticipantsList = ValueNotifier([]);

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(calendarEventProvider(widget.calendarId));
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: event.when(
        data: (calendarEvent) {
          // Update event participants list
          updateEventParticipantsList(calendarEvent);

          return CustomScrollView(
            slivers: [
              _buildEventAppBar(calendarEvent),
              _buildEventBody(calendarEvent),
            ],
          );
        },
        error: (error, stackTrace) =>
            Text(L10n.of(context).errorLoadingEventDueTo(error)),
        loading: () => const EventDetailsSkeleton(),
      ),
    );
  }

  Future<void> updateEventParticipantsList(CalendarEvent ev) async {
    final ffiListFfiString = await ev.participants();
    final participantsList = asDartStringList(ffiListFfiString);
    _log.info('Event Participants => $participantsList');
    if (!mounted) return;
    eventParticipantsList.value = participantsList;
  }

  Widget _buildEventAppBar(CalendarEvent calendarEvent) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      actions: [
        _buildShareAction(calendarEvent),
        _buildActionMenu(calendarEvent),
      ],
      flexibleSpace: Container(
        padding: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(gradient: primaryGradient),
        child: const FlexibleSpaceBar(
          background: Icon(Atlas.calendar_dots, size: 80),
        ),
      ),
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
            key: EventsKeys.eventEditBtn,
            onTap: () => context.pushNamed(
              Routes.editCalendarEvent.name,
              pathParameters: {'calendarId': widget.calendarId},
            ),
            child: Row(
              children: <Widget>[
                const Icon(Atlas.pencil_edit_thin),
                const SizedBox(width: 10),
                Text(L10n.of(context).eventEdit),
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
            key: EventsKeys.eventDeleteBtn,
            onTap: () => showAdaptiveDialog(
              context: context,
              builder: (context) => RedactContentWidget(
                removeBtnKey: EventsKeys.eventRemoveBtn,
                title: L10n.of(context).removeThisPost,
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
                Text(L10n.of(context).eventRemove),
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
            title: L10n.of(context).reportThisEvent,
            description: L10n.of(context).reportThisContent,
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
            Text(L10n.of(context).eventReport),
          ],
        ),
      ),
    );

    return PopupMenuButton(
      key: EventsKeys.appbarMenuActionBtn,
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
          AttachmentSectionWidget(manager: calendarEvent.attachments()),
          const SizedBox(height: 40),
          CommentsSection(manager: calendarEvent.comments()),
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
                Row(
                  children: [
                    const Icon(Atlas.accounts_group_people),
                    const SizedBox(width: 10),
                    ValueListenableBuilder(
                      valueListenable: eventParticipantsList,
                      builder: (context, eventParticipantsList, child) {
                        return Text(
                          L10n.of(context)
                              .peopleGoing(eventParticipantsList.length),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onRsvp(RsvpStatusTag status, WidgetRef ref) async {
    EasyLoading.show(status: L10n.of(context).updatingRSVP);
    try {
      final event =
          await ref.read(calendarEventProvider(widget.calendarId).future);
      final rsvpManager = await event.rsvps();
      final draft = rsvpManager.rsvpDraft();
      switch (status) {
        case RsvpStatusTag.Yes:
          draft.status('yes');
          break;
        case RsvpStatusTag.No:
          draft.status('no');
          break;
        case RsvpStatusTag.Maybe:
          draft.status('maybe');
          break;
      }
      final rsvpId = await draft.send();
      _log.info('new rsvp id: $rsvpId');
      // refresh cache
      final client = ref.read(alwaysClientProvider);
      await client.waitForRsvp(rsvpId.toString(), null);
      EasyLoading.dismiss();
      // refresh UI of this page & outer page
      ref.invalidate(myRsvpStatusProvider(widget.calendarId));
    } catch (e, s) {
      _log.severe('Error =>', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(e.toString(), duration: const Duration(seconds: 3));
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
            key: EventsKeys.eventRsvpGoingBtn,
            onTap: () => onRsvp(RsvpStatusTag.Yes, ref),
            iconData: Icons.check,
            actionName: L10n.of(context).going,
            isSelected: rsvp.single == RsvpStatusTag.Yes,
          ),
          _buildVerticalDivider(),
          _buildEventRsvpActionItem(
            key: EventsKeys.eventRsvpNotGoingBtn,
            onTap: () => onRsvp(RsvpStatusTag.No, ref),
            iconData: Icons.close,
            actionName: L10n.of(context).notGoing,
            isSelected: rsvp.single == RsvpStatusTag.No,
          ),
          _buildVerticalDivider(),
          _buildEventRsvpActionItem(
            key: EventsKeys.eventRsvpMaybeBtn,
            onTap: () => onRsvp(RsvpStatusTag.Maybe, ref),
            iconData: Icons.question_mark,
            actionName: L10n.of(context).maybe,
            isSelected: rsvp.single == RsvpStatusTag.Maybe,
          ),
        ],
      ),
    );
  }

  Widget _buildShareAction(CalendarEvent calendarEvent) {
    return PopupMenuButton(
      icon: const Icon(Icons.share),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          onTap: () => onShareEvent(calendarEvent),
          child: Row(
            children: <Widget>[
              const Icon(Icons.share),
              const SizedBox(width: 10),
              Text(L10n.of(context).shareIcal),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> onShareEvent(CalendarEvent event) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filename = event.title().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final icalPath = join(tempDir.path, '$filename.ics');
      event.icalForSharing(icalPath);

      await Share.shareXFiles([
        XFile(
          icalPath,
          mimeType: 'text/calendar',
        ),
      ]);
    } catch (error, stack) {
      _log.severe('Creating iCal Share Event failed:', error, stack);
      // ignore: use_build_context_synchronously
      EasyLoading.showError(L10n.of(context).shareFailed(error));
    }
  }

  Widget _buildEventRsvpActionItem({
    required Key key,
    required VoidCallback onTap,
    required IconData iconData,
    required String actionName,
    bool isSelected = false,
  }) {
    return Expanded(
      child: InkWell(
        key: key,
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
          ListTile(
            leading: const Icon(Atlas.accounts_group_people),
            title: participantsListUI(ev.roomIdStr()),
          ),
        ],
      ),
    );
  }

  Widget participantsListUI(String roomId) {
    return ValueListenableBuilder(
      valueListenable: eventParticipantsList,
      builder: (context, eventParticipantsList, child) {
        if (eventParticipantsList.isEmpty) {
          return Text(L10n.of(context).noParticipantsGoing);
        }

        final membersCount = eventParticipantsList.length;
        List<String> firstFiveEventParticipantsList = eventParticipantsList;
        if (membersCount > 5) {
          firstFiveEventParticipantsList = firstFiveEventParticipantsList.sublist(0, 5);
        }

        return GestureDetector(
          onTap: () => showAllParticipantListDialog(roomId),
          child: Wrap(
            direction: Axis.horizontal,
            spacing: -10,
            children: [
              ...firstFiveEventParticipantsList.map(
                (a) => MemberAvatar(
                  memberId: a,
                  roomId: roomId,
                ),
              ),
              if (membersCount > 5)
                CircleAvatar(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      '+${membersCount - 5}',
                      textAlign: TextAlign.center,
                      textScaler: const TextScaler.linear(0.8),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void showAllParticipantListDialog(String roomId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: ParticipantsList(
            roomId: roomId,
            participants: eventParticipantsList.value,
          ),
        );
      },
    );
  }

  ActerAvatar fallbackAvatar(String roomId) {
    return ActerAvatar(
      mode: DisplayMode.Space,
      avatarInfo: AvatarInfo(uniqueId: roomId),
    );
  }

  Widget _buildEventDescription(CalendarEvent ev) {
    TextMessageContent? content = ev.description();
    final formattedText = content?.formatted();
    final bodyText = content?.body() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            L10n.of(context).about,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          if (formattedText != null)
            RenderHtml(
              text: formattedText,
              defaultTextStyle: Theme.of(context).textTheme.labelMedium,
            )
          else
            Text(
              bodyText,
              style: Theme.of(context).textTheme.labelMedium,
            ),
        ],
      ),
    );
  }
}
