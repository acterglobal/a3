import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/events/providers/events_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarEventPage extends ConsumerWidget {
  final String calendarId;

  const CalendarEventPage({super.key, required this.calendarId});

  Widget buildActions(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) {
    final spaceId = event.roomIdStr();
    List<PopupMenuEntry> actions = [];
    final membership = ref.watch(spaceMembershipProvider(spaceId));
    if (membership.valueOrNull != null) {
      final memb = membership.requireValue!;
      if (memb.canString('CanPostEvent')) {
        actions.add(
          PopupMenuItem(
            onTap: () => context.pushNamed(
              Routes.editCalendarEvent.name,
              pathParameters: {'calendarId': calendarId},
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

      if (memb.canString('CanRedact') ||
          memb.userId().toString() == event.sender().toString()) {
        actions.addAll([
          PopupMenuItem(
            onTap: () => showAdaptiveDialog(
              context: context,
              builder: (context) => RedactContentWidget(
                title: 'Redact this post',
                eventId: event.eventId().toString(),
                onSuccess: () {
                  ref.invalidate(calendarEventProvider);
                  if (context.mounted) {
                    context.go('/');
                  }
                },
                senderId: event.sender().toString(),
                roomId: event.roomIdStr(),
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
                const Text('Redact Event'),
              ],
            ),
          ),
        ]);
      }
    } else {
      actions.add(
        PopupMenuItem(
          onTap: () => showAdaptiveDialog(
            context: context,
            builder: (ctx) => ReportContentWidget(
              title: 'Report this Event',
              description:
                  'Report this content to your homeserver administrator. Please note that your administrator won\'t be able to read or view files in encrypted spaces.',
              eventId: calendarId,
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
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton(
      itemBuilder: (ctx) => actions,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(calendarEventProvider(calendarId));

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: event.hasValue ? event.value!.title() : 'Loading Event',
            sectionColor: Colors.blue.shade200,
            actions: [
              event.maybeWhen(
                data: (event) => buildActions(context, ref, event),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          event.when(
            data: (ev) {
              String dateTime = 'Date and Time: ${formatDt(ev)}';
              String description = '';
              TextMessageContent? content = ev.description();
              if (content != null) {
                description = 'Description: ${content.body()}';
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Card(
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        key: Key(calendarId),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev.title()),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 15),
                              Text(dateTime),
                              const SizedBox(height: 15),
                              Text(description),
                              const SizedBox(height: 15),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 50,
                                width: 100,
                                child: DefaultButton(
                                  title: 'Invite',
                                  onPressed: () => onInvite(context),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                                width: 100,
                                child: DefaultButton(
                                  title: 'Join',
                                  onPressed: () => onJoin(context),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                                width: 100,
                                child: PopupMenuButton(
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: const Text('RSVP'),
                                  ),
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry>[
                                    PopupMenuItem(
                                      onTap: () => onRsvp(context, ev, 'Yes'),
                                      child: const Text('Yes'),
                                    ),
                                    PopupMenuItem(
                                      onTap: () => onRsvp(context, ev, 'Maybe'),
                                      child: const Text('Maybe'),
                                    ),
                                    PopupMenuItem(
                                      onTap: () => onRsvp(context, ev, 'No'),
                                      child: const Text('No'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            error: (error, stackTrace) => SliverToBoxAdapter(
              child: Text('Error loading event due to $error'),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  void onDelete(BuildContext context) {
    customMsgSnackbar(context, 'Delete Event is not implemented yet');
  }

  void onInvite(BuildContext context) {
    customMsgSnackbar(context, 'Invite to event is not available yet');
  }

  void onJoin(BuildContext context) {
    customMsgSnackbar(context, 'Join event is not available yet');
  }

  Future<void> onRsvp(
    BuildContext context,
    CalendarEvent event,
    String status,
  ) async {
    final rsvpManager = await event.rsvpManager();
    int count = rsvpManager.totalRsvpCount();
    debugPrint('rsvp prev count: $count');

    final draft = rsvpManager.rsvpDraft();
    draft.status(status);
    final rsvpId = await draft.send();
    debugPrint('new rsvp id: $rsvpId');

    // rsvpManager.subscribeStream();
    // count = rsvpManager.totalRsvpCount();
    // debugPrint('rsvp count: $count');
  }
}
