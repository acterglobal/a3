import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';
import 'package:material_segmented_control/material_segmented_control.dart';

class CalendarEventPage extends ConsumerStatefulWidget {
  final String calendarId;

  const CalendarEventPage({super.key, required this.calendarId});

  @override
  ConsumerState<CalendarEventPage> createState() => _CalendarEventPageState();
}

class _CalendarEventPageState extends ConsumerState<CalendarEventPage> {
  RsvpStatusTag? rsvpStatus;

  @override
  void initState() {
    super.initState();
    final myRsvpStatus = ref.read(myRsvpStatusProvider(widget.calendarId));
    myRsvpStatus.maybeWhen(
      data: (data) {
        final status = data.statusStr(); // kebab-case
        if (status != null) {
          switch (status) {
            case 'yes':
              rsvpStatus = RsvpStatusTag.Yes;
              break;
            case 'maybe':
              rsvpStatus = RsvpStatusTag.Maybe;
              break;
            case 'no':
              rsvpStatus = RsvpStatusTag.No;
              break;
          }
        }
      },
      orElse: () => null,
    );
  }

  Widget buildActions(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) {
    final spaceId = event.roomIdStr();
    final membership = ref.watch(roomMembershipProvider(spaceId));
    List<PopupMenuEntry> actions = [];
    final senderId = event.sender().toString();
    if (membership.valueOrNull != null) {
      final memb = membership.requireValue!;
      if (memb.canString('CanPostEvent')) {
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

      if (memb.canString('CanRedactOwn') &&
          memb.userId().toString() == senderId) {
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
                      pathParameters: {'spaceId': spaceId},
                    );
                  }
                },
                senderId: senderId,
                roomId: spaceId,
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
              eventId: widget.calendarId,
              roomId: spaceId,
              senderId: senderId,
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

    return PopupMenuButton(itemBuilder: (ctx) => actions);
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(calendarEventProvider(widget.calendarId));
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          Consumer(
            builder: (context, ref, child) {
              return PageHeaderWidget(
                title: event.hasValue ? event.value!.title() : 'Loading Event',
                sectionDecoration: const BoxDecoration(
                  gradient: primaryGradient,
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
              String date = formatDate(ev);
              final start = ev.utcStart().timestampMillis();
              final end = ev.utcEnd().timestampMillis();
              String time =
                  '${Jiffy.parseFromMillisecondsSinceEpoch(start).jm} - ${Jiffy.parseFromMillisecondsSinceEpoch(end).jm}';
              String description = '';
              TextMessageContent? content = ev.description();

              if (content != null && content.body().isNotEmpty) {
                description = content.body();
              }
              return SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  key: Key(widget.calendarId),
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
                    MaterialSegmentedControl(
                      children: const {
                        RsvpStatusTag.Yes: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Yes'),
                        ),
                        RsvpStatusTag.Maybe: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Maybe'),
                        ),
                        RsvpStatusTag.No: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('No'),
                        ),
                      },
                      selectionIndex: rsvpStatus,
                      borderColor: Colors.grey,
                      selectedColor: Colors.transparent,
                      unselectedColor: Colors.transparent,
                      selectedTextStyle: const TextStyle(color: Colors.white),
                      unselectedTextStyle: const TextStyle(color: Colors.grey),
                      // borderWidth: 0.7,
                      // borderRadius: 32,
                      onSegmentTapped: (value) async {
                        await onRsvp(context, value, ref);
                        setState(() => rsvpStatus = value);
                        // refresh outer page
                        ref.invalidate(myRsvpStatusProvider(widget.calendarId));
                      },
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

  Future<void> onRsvp(
    BuildContext context,
    RsvpStatusTag status,
    WidgetRef ref,
  ) async {
    EasyLoading.show(status: 'Updating RSVP', dismissOnTap: false);
    final event =
        await ref.read(calendarEventProvider(widget.calendarId).future);
    final rsvpManager = await event.rsvpManager();
    final draft = rsvpManager.rsvpDraft();
    draft.status(status.name.toLowerCase()); // pascal case
    final rsvpId = await draft.send();
    EasyLoading.dismiss();
    debugPrint('new rsvp id: $rsvpId');
  }
}
