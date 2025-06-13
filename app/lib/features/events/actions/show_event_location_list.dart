import 'package:flutter/material.dart';
import 'package:acter/features/events/widgets/event_location_list_widget.dart';

void showEventLocationList(BuildContext context, {String? eventId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) {
      return EventLocationListWidget(
        eventId: eventId,
      );
    },
  );
} 