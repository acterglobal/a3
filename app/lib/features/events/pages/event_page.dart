import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';

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
    final membership = ref.watch(roomMembershipProvider(spaceId));
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
    final myRsvpStatus = ref.watch(myRsvpStatusProvider(calendarId));
    final List<bool> rsvp = [false, false, false];
    myRsvpStatus.maybeWhen(
      data: (status) {
        if (status == 'Yes') {
          return rsvp.setAll(0, [false, false, true]);
        }
        if (status == 'Maybe') {
          return rsvp.setAll(0, [false, true, false]);
        }
        if (status == 'No') {
          return rsvp.setAll(0, [true, false, false]);
        }
      },
      orElse: () => null,
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          Consumer(
            builder: (context, ref, child) {
              return PageHeaderWidget(
                title: event.hasValue ? event.value!.title() : 'Loading Event',
                sectionDecoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                expandedHeight: 0,
                actions: [
                  event.maybeWhen(
                    data: (event) => buildActions(context, ref, event),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
          event.when(
            data: (ev) {
              String date = formatDt(ev);
              String time =
                  '${Jiffy.parseFromMillisecondsSinceEpoch(ev.utcStart().timestampMillis()).jm} - ${Jiffy.parseFromMillisecondsSinceEpoch(ev.utcEnd().timestampMillis()).jm}';
              String description = '';
              TextMessageContent? content = ev.description();

              if (content != null && content.body().isNotEmpty) {
                description = content.body();
              }
              return SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  key: Key(calendarId),
                  children: [
                    const SizedBox(height: 50),
                    Flexible(
                      flex: 1,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        child: Card(
                          elevation: 0,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  ev.title(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 5,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(width: 50),
                                    Flexible(
                                      flex: 2,
                                      child: Text(
                                        date,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 5,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(width: 50),
                                    Flexible(
                                      flex: 2,
                                      child: Text(
                                        time,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, child) {
                                  // final profile = ref.watch(
                                  //   spaceMemberProfileProvider(spaceMember),
                                  // );
                                  return Container(
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Host: ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        const SizedBox(width: 50),
                                        // profile.when(
                                        //   data: (data) => Flexible(
                                        //     flex: 2,
                                        //     child: Wrap(
                                        //       spacing: 4.0,
                                        //       children: [
                                        //         Text(
                                        //           data.displayName ??
                                        //               spaceMember.userId,
                                        //           style: Theme.of(context)
                                        //               .textTheme
                                        //               .bodyMedium,
                                        //         ),
                                        //         ActerAvatar(
                                        //           uniqueId: spaceMember.userId,
                                        //           mode: DisplayMode.User,
                                        //           avatar: data.getAvatarImage(),
                                        //         ),
                                        //       ],
                                        //     ),
                                        //   ),
                                        //   error: (err, st) => Flexible(
                                        //     flex: 2,
                                        //     child: Text(
                                        //       'Error loading host profile: $err',
                                        //     ),
                                        //   ),
                                        //   loading: () =>
                                        //       const CircularProgressIndicator(),
                                        // ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                              Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 5,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Description: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    Flexible(
                                      flex: 2,
                                      child: Text(
                                        description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ToggleButtons(
                      isSelected: rsvp,
                      onPressed: (index) async {
                        var status = '';
                        if (index == 0) status = 'No';
                        if (index == 1) status = 'Maybe';
                        if (index == 2) status = 'Yes';
                        await onRsvp(context, event.value!, status);
                        ref.invalidate(myRsvpStatusProvider);
                      },
                      textStyle: Theme.of(context).textTheme.labelMedium,
                      borderRadius: BorderRadius.circular(12),
                      fillColor: Theme.of(context).colorScheme.success,
                      borderColor: Theme.of(context).colorScheme.neutral6,
                      borderWidth: 0.5,
                      selectedBorderColor:
                          Theme.of(context).colorScheme.neutral6,
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Maybe'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Yes'),
                        ),
                      ],
                    ),
                  ],
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
    final draft = rsvpManager.rsvpDraft();
    draft.status(status);
    final rsvpId = await draft.send();
    debugPrint('new rsvp id: $rsvpId');
  }
}
