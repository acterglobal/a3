import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/events/providers/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalendarEventPage extends ConsumerWidget {
  final String calendarId;
  const CalendarEventPage({super.key, required this.calendarId});

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
              PopupMenuButton(
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    onTap: () => context.pushNamed(
                      Routes.editCalendarEvent.name,
                      pathParameters: {'calendarId': calendarId},
                    ),
                    child: const Text('Edit Event'),
                  ),
                  PopupMenuItem(
                    onTap: () => customMsgSnackbar(
                      context,
                      'Delete Event is not implemented yet',
                    ),
                    child: const Text('Delete Event'),
                  ),
                ],
              ),
            ],
          ),
          event.when(
            data: (calendarEvent) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          key: Key(
                            calendarEvent.eventId().toString(),
                          ),
                          title: Text(calendarEvent.title()),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date and Time: ${formatDt(calendarEvent)}',
                              ),
                              const SizedBox(height: 15),
                              Text(
                                calendarEvent.description() != null
                                    ? 'Description: ${calendarEvent.description()!.body()}'
                                    : '',
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                          trailing: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 50,
                                width: 100,
                                child: CustomButton(
                                  title: 'Invite',
                                  onPressed: () => customMsgSnackbar(
                                    context,
                                    'Invite to event is not available yet',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 50,
                                width: 100,
                                child: CustomButton(
                                  title: 'Join',
                                  onPressed: () => customMsgSnackbar(
                                    context,
                                    'Join event is not available yet',
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
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
}
