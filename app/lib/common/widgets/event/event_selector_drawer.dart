import 'package:acter/features/events/pages/event_list_page.dart';
import 'package:flutter/material.dart';

Future<String?> selectEventDrawer({
  required BuildContext context,
  String? spaceId,
}) async {
  final eventId = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (context) => EventListPage(
      spaceId: spaceId,
      onSelectEventItem: (eventId) => Navigator.pop(context, eventId),
    ),
  );
  return eventId == '' ? null : eventId;
}
