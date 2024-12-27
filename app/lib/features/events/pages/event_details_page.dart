import 'dart:io';

import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/actions/report_content.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/share/action/share_space_object_action.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/bookmarks/widgets/bookmark_action.dart';
import 'package:acter/features/comments/types.dart';
import 'package:acter/features/comments/widgets/comments_section_widget.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter/features/events/widgets/change_date_sheet.dart';
import 'package:acter/features/events/widgets/event_date_widget.dart';
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
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::cal_event::details');

class EventDetailPage extends ConsumerStatefulWidget {
  final String calendarId;

  const EventDetailPage({
    super.key,
    required this.calendarId,
  });

  @override
  ConsumerState<EventDetailPage> createState() =>
      _EventDetailPageConsumerState();
}

class _EventDetailPageConsumerState extends ConsumerState<EventDetailPage> {
  @override
  Widget build(BuildContext context) {
    final calEventLoader = ref.watch(calendarEventProvider(widget.calendarId));
    final errored = calEventLoader.asError;
    if (errored != null) {
      _log.severe(
        'Failed to load cal event',
        errored.error,
        errored.stackTrace,
      );
      return ErrorPage(
        background: const EventDetailsSkeleton(),
        error: errored.error,
        stack: errored.stackTrace,
        textBuilder: L10n.of(context).errorLoadingEventDueTo,
        onRetryTap: () {
          ref.invalidate(calendarEventProvider(widget.calendarId));
        },
      );
    }
    final calEvent = calEventLoader.valueOrNull;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildEventAppBar(calEvent),
          _buildEventBody(calEvent),
        ],
      ),
    );
  }

  Widget _buildEventAppBar(CalendarEvent? calendarEvent) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      actions: calendarEvent != null
          ? [
              IconButton(
                icon: PhosphorIcon(PhosphorIcons.shareFat()),
                onPressed: () => onShareEvent(context, calendarEvent),
              ),
              BookmarkAction(
                bookmarker: BookmarkType.forEvent(widget.calendarId),
              ),
              _buildActionMenu(calendarEvent),
            ]
          : [],
      flexibleSpace: Container(
        padding: const EdgeInsets.only(top: 20),
        child: const FlexibleSpaceBar(
          background: Icon(
            Atlas.calendar_dots,
            size: 80,
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(CalendarEvent event) {
    final lang = L10n.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    //Get membership details
    final spaceId = event.roomIdStr();
    final canRedact = ref.watch(canRedactProvider(event));
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    final canPostEvent = membership?.canString('CanPostEvent') == true;
    final canChangeDate =
        ref.watch(eventTypeProvider(event)) == EventFilters.upcoming;

    //Create event actions
    List<PopupMenuEntry> actions = [];

    if (membership != null) {
      //Edit Event Action
      if (canPostEvent) {
        // Edit Title
        actions.add(
          PopupMenuItem(
            key: EventsKeys.eventEditBtn,
            onTap: () => showEditEventTitleBottomSheet(event),
            child: Row(
              children: <Widget>[
                const Icon(Atlas.pencil_edit_thin),
                const SizedBox(width: 10),
                Text(lang.editTitle),
              ],
            ),
          ),
        );

        // Edit Description
        actions.add(
          PopupMenuItem(
            key: EventsKeys.eventEditBtn,
            onTap: () => showEditDescriptionSheet(event),
            child: Row(
              children: <Widget>[
                const Icon(Atlas.pencil_edit_thin),
                const SizedBox(width: 10),
                Text(lang.editDescription),
              ],
            ),
          ),
        );

        // Change Date
        if (canChangeDate) {
          actions.add(
            PopupMenuItem(
              key: EventsKeys.eventEditBtn,
              onTap: () => showChangeDateSheet(event),
              child: Row(
                children: <Widget>[
                  const Icon(Atlas.pencil_edit_thin),
                  const SizedBox(width: 10),
                  Text(lang.changeDate),
                ],
              ),
            ),
          );
        }

        // Copy as New
        actions.add(
          PopupMenuItem(
            onTap: () {
              context.pushNamed(
                Routes.createEvent.name,
                extra: event,
              );
            },
            child: Row(
              children: <Widget>[
                Icon(PhosphorIcons.calendarPlus()),
                const SizedBox(width: 10),
                Text(lang.createAcopy),
              ],
            ),
          ),
        );
      }
    }

    //Delete Event Action
    if (canRedact.valueOrNull == true) {
      actions.addAll([
        PopupMenuItem(
          key: EventsKeys.eventDeleteBtn,
          onTap: () => openRedactContentDialog(
            context,
            removeBtnKey: EventsKeys.eventRemoveBtn,
            title: lang.removeThisPost,
            eventId: event.eventId().toString(),
            onSuccess: () {
              Navigator.pop(context);
            },
            roomId: spaceId,
            isSpace: true,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Atlas.trash_can_thin,
                color: colorScheme.error,
              ),
              const SizedBox(width: 10),
              Text(lang.eventRemove),
            ],
          ),
        ),
      ]);
    }

    //Report Event Action
    actions.add(
      PopupMenuItem(
        onTap: () => openReportContentDialog(
          context,
          title: lang.reportThisEvent,
          description: lang.reportThisContent,
          eventId: widget.calendarId,
          roomId: spaceId,
          senderId: event.sender().toString(),
          isSpace: true,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Atlas.warning_thin,
              color: colorScheme.error,
            ),
            const SizedBox(width: 10),
            Text(lang.eventReport),
          ],
        ),
      ),
    );

    return PopupMenuButton(
      key: EventsKeys.appbarMenuActionBtn,
      itemBuilder: (context) => actions,
    );
  }

  Widget _buildEventBody(CalendarEvent? calendarEvent) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        key: Key('cal-event-${widget.calendarId}'),
        children: [
          if (calendarEvent != null) ...[
            const SizedBox(height: 20),
            _buildEventBasicDetails(calendarEvent),
            const SizedBox(height: 10),
            _buildEventRsvpActions(calendarEvent),
            const SizedBox(height: 10),
            _buildEventDataSet(calendarEvent),
            const SizedBox(height: 10),
            _buildEventDescription(calendarEvent),
            const SizedBox(height: 40),
          ] else
            const EventDetailsSkeleton(),
          if (calendarEvent != null)
            AttachmentSectionWidget(
              manager: calendarEvent.asAttachmentsManagerProvider(),
              spaceObjectDetails: (
                spaceId: calendarEvent.roomIdStr(),
                objectType: ObjectType.calendarEvent,
                objectId: widget.calendarId,
              ),
            ),
          const SizedBox(height: 40),
          CommentsSectionWidget(
            managerProvider: calendarEvent?.asCommentsManagerProvider(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEventBasicDetails(CalendarEvent calendarEvent) {
    final spaceId = calendarEvent.roomIdStr();
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    final canPostEvent = membership?.canString('CanPostEvent') == true;
    final eventType = ref.watch(eventTypeProvider(calendarEvent));
    final eventParticipantsList =
        ref.watch(participantsProvider(widget.calendarId)).valueOrNull;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and Month
        EventDateWidget(calendarEvent: calendarEvent, eventType: eventType),
        // Title, Space, User counts, comments counts and like counts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectionArea(
                child: GestureDetector(
                  onTap: () {
                    if (canPostEvent) {
                      showEditEventTitleBottomSheet(calendarEvent);
                    }
                  },
                  child: Text(
                    calendarEvent.title(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SpaceChip(
                spaceId: spaceId,
                useCompactView: true,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Atlas.accounts_group_people),
                  const SizedBox(width: 10),
                  Text(
                    L10n.of(context)
                        .peopleGoing(eventParticipantsList?.length ?? 0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showEditEventTitleBottomSheet(CalendarEvent calendarEvent) {
    showEditTitleBottomSheet(
      context: context,
      titleValue: calendarEvent.title(),
      onSave: (newName) {
        saveEventTitle(
          context: context,
          calendarEvent: calendarEvent,
          newName: newName,
        );
      },
    );
  }

  Future<void> onRsvp(RsvpStatusTag status, WidgetRef ref) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.updatingRSVP);
    try {
      final event =
          await ref.read(calendarEventProvider(widget.calendarId).future);
      final rsvpManager = await event.rsvps();
      final draft = rsvpManager.rsvpDraft();
      final statusStr = switch (status) {
        RsvpStatusTag.Yes => 'yes',
        RsvpStatusTag.No => 'no',
        RsvpStatusTag.Maybe => 'maybe',
      };
      draft.status(statusStr);
      final rsvpId = await draft.send();
      _log.info('new rsvp id: $rsvpId');
      // refresh cache
      final client = ref.read(alwaysClientProvider);
      await client.waitForRsvp(rsvpId.toString(), null);
      EasyLoading.dismiss();
    } catch (e, s) {
      _log.severe('Failed to send RSVP', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.sendingRsvpFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildEventRsvpActions(CalendarEvent calendarEvent) {
    final lang = L10n.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final rsvp = ref.watch(myRsvpStatusProvider(widget.calendarId)).valueOrNull;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        children: [
          _buildEventRsvpActionItem(
            key: EventsKeys.eventRsvpGoingBtn,
            calendarEvent: calendarEvent,
            onTap: () => onRsvp(RsvpStatusTag.Yes, ref),
            iconData: Icons.check,
            actionName: lang.going,
            rsvpStatusColor: colorScheme.secondary,
            isSelected: rsvp == RsvpStatusTag.Yes,
          ),
          _buildVerticalDivider(),
          _buildEventRsvpActionItem(
            key: EventsKeys.eventRsvpNotGoingBtn,
            calendarEvent: calendarEvent,
            onTap: () => onRsvp(RsvpStatusTag.No, ref),
            iconData: Icons.close,
            actionName: lang.notGoing,
            rsvpStatusColor: colorScheme.error,
            isSelected: rsvp == RsvpStatusTag.No,
          ),
          _buildVerticalDivider(),
          _buildEventRsvpActionItem(
            key: EventsKeys.eventRsvpMaybeBtn,
            calendarEvent: calendarEvent,
            onTap: () => onRsvp(RsvpStatusTag.Maybe, ref),
            iconData: Icons.question_mark,
            actionName: lang.maybe,
            rsvpStatusColor: Colors.white,
            isSelected: rsvp == RsvpStatusTag.Maybe,
          ),
        ],
      ),
    );
  }

  Future<void> onShareEvent(BuildContext context, CalendarEvent event) async {
    final lang = L10n.of(context);
    try {
      final filename = event.title().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final tempDir = await getTemporaryDirectory();
      final icalPath = join(tempDir.path, '$filename.ics');
      event.icalForSharing(icalPath);

      if (context.mounted) {
        openShareSpaceObjectDialog(
          context: context,
          spaceObjectDetails: (
            spaceId: event.roomIdStr(),
            objectType: ObjectType.calendarEvent,
            objectId: widget.calendarId,
          ),
          fileDetails: (
            file: File(icalPath),
            mimeType: 'text/calendar',
          ),
        );
      }
    } catch (e, s) {
      _log.severe('Creating iCal share Event failed', e, s);
      if (!mounted) return;
      EasyLoading.showError(
        lang.shareFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildEventRsvpActionItem({
    required Key key,
    required CalendarEvent calendarEvent,
    required VoidCallback onTap,
    required IconData iconData,
    required String actionName,
    required Color rsvpStatusColor,
    bool isSelected = false,
  }) {
    final canRSVPUpdate =
        ref.watch(eventTypeProvider(calendarEvent)) != EventFilters.past;
    return Expanded(
      child: InkWell(
        key: key,
        onTap: canRSVPUpdate ? onTap : null,
        child: Column(
          children: [
            Icon(
              iconData,
              size: 26,
              color: isSelected ? rsvpStatusColor : Colors.white38,
            ),
            const SizedBox(height: 4),
            Text(
              actionName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected ? rsvpStatusColor : Colors.white38,
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
    final lang = L10n.of(context);
    final agoTime =
        Jiffy.parseFromDateTime(toDartDatetime(ev.utcStart()).toLocal())
            .endOf(Unit.hour)
            .fromNow();

    String eventDateTime = '${formatDate(ev)} (${formatTime(ev)})';
    final eventType = ref.watch(eventTypeProvider(ev));

    String eventTimingTitle = switch (eventType) {
      EventFilters.ongoing => '${lang.eventStarted} $agoTime',
      EventFilters.upcoming => '${lang.eventStarts} $agoTime',
      EventFilters.past => '${lang.eventEnded} $agoTime',
      _ => '',
    };
    final canChangeDate = eventType == EventFilters.upcoming;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Atlas.clock_time),
            title: Text(eventTimingTitle),
            onTap: canChangeDate ? () => showChangeDateSheet(ev) : null,
          ),
          ListTile(
            leading: const Icon(Atlas.calendar_dots),
            title: Text(eventDateTime),
            onTap: canChangeDate ? () => showChangeDateSheet(ev) : null,
          ),
          ListTile(
            leading: const Icon(Atlas.accounts_group_people),
            title: participantsListUI(ev.roomIdStr()),
          ),
        ],
      ),
    );
  }

  void showChangeDateSheet(CalendarEvent ev) {
    showChangeDateBottomSheet(
      context: context,
      calendarId: ev.eventId().toString(),
    );
  }

  Widget participantsListUI(String roomId) {
    final eventParticipantsList =
        ref.watch(participantsProvider(widget.calendarId)).valueOrNull ?? [];
    if (eventParticipantsList.isEmpty) {
      return Text(L10n.of(context).noParticipantsGoing);
    }

    final membersCount = eventParticipantsList.length;
    List<String> firstFiveEventParticipantsList = eventParticipantsList;
    if (membersCount > 5) {
      firstFiveEventParticipantsList =
          firstFiveEventParticipantsList.sublist(0, 5);
    }

    return GestureDetector(
      onTap: () => showAllParticipantListDialog(roomId, eventParticipantsList),
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
  }

  void showAllParticipantListDialog(
    String roomId,
    List<String> eventParticipantsList,
  ) {
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
            participants: eventParticipantsList,
          ),
        );
      },
    );
  }

  ActerAvatar fallbackAvatar(String roomId) {
    return ActerAvatar(
      options: AvatarOptions(AvatarInfo(uniqueId: roomId)),
    );
  }

  Widget _buildEventDescription(CalendarEvent ev) {
    final textTheme = Theme.of(context).textTheme;
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
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          SelectionArea(
            child: GestureDetector(
              onTap: () => showEditDescriptionSheet(ev),
              child: formattedText != null
                  ? RenderHtml(
                      text: formattedText,
                      defaultTextStyle: textTheme.labelMedium,
                    )
                  : Text(
                      bodyText,
                      style: textTheme.labelMedium,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void showEditDescriptionSheet(CalendarEvent ev) {
    TextMessageContent? content = ev.description();
    showEditHtmlDescriptionBottomSheet(
      context: context,
      descriptionHtmlValue: content?.formatted(),
      descriptionMarkdownValue: content?.body(),
      onSave: (htmlBodyDescription, plainDescription) {
        saveEventDescription(
          context: context,
          calendarEvent: ev,
          htmlBodyDescription: htmlBodyDescription,
          plainDescription: plainDescription,
        );
      },
    );
  }
}
