import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/events/providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarEventPage extends ConsumerWidget {
  final String calendarId;

  const CalendarEventPage({
    super.key,
    required this.calendarId,
  });

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
        actions.addAll([
          PopupMenuItem(
            onTap: () => showAdaptiveDialog(
              context: context,
              builder: (context) => RedactContentWidget(
                title: 'Remove this post',
                eventId: event.eventId().toString(),
                senderId: event.sender().toString(),
                roomId: spaceId,
                isSpace: true,
                onRemove: () => ref
                    .read(redactEventProvider.notifier)
                    .redact(spaceId, event.eventId().toString(), ''),
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
    final myStatus = ref.watch(rsvpStatusProvider(calendarId));
    final participants = ref.watch(rsvpUsersProvider(calendarId));
    var event = ref.watch(calendarEventProvider(calendarId));
    ref.listen(redactEventProvider, (previous, next) {
      next.whenData((res) {
        if (res == null) return null;
        context.pop();
        context.pop();
      });
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          Consumer(
            builder: (context, ref, child) {
              return PageHeaderWidget(
                title: 'Calendar Event',
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
                                        formatDt(ev),
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
                                        formatTime(ev),
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
                                      'Host: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(width: 50),
                                    Flexible(
                                      flex: 2,
                                      child: ActerAvatar(
                                        uniqueId: ev.sender().toString(),
                                        mode: DisplayMode.User,
                                        size: 22,
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
                                      'Participants: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(width: 50),
                                    participants.when(
                                      data: (users) {
                                        return Flexible(
                                          flex: 2,
                                          child: Wrap(
                                            spacing: -4.0,
                                            children: List.generate(
                                              users.length,
                                              (idx) => ActerAvatar(
                                                uniqueId: users[idx],
                                                mode: DisplayMode.User,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      error: (e, st) => Text(
                                        'Error loading participants $e',
                                      ),
                                      loading: () =>
                                          const CircularProgressIndicator(),
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
                      isSelected: [
                        myStatus.hasValue
                            ? myStatus.value == 'No'
                                ? true
                                : false
                            : false,
                        myStatus.hasValue
                            ? myStatus.value == 'Maybe'
                                ? true
                                : false
                            : false,
                        myStatus.hasValue
                            ? myStatus.value == 'Yes'
                                ? true
                                : false
                            : false,
                      ],
                      onPressed: (index) async {
                        var status = '';
                        if (index == 0) status = 'No';
                        if (index == 1) status = 'Maybe';
                        if (index == 2) status = 'Yes';
                        ref
                            .read(setRsvpProvider(calendarId).notifier)
                            .setRsvp(status);
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
}
