import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventTypeProvider = Provider.autoDispose
    .family<EventFilters, ffi.CalendarEvent>((ref, event) {
      DateTime eventStartDateTime = toDartDatetime(event.utcStart());
      DateTime eventEndDateTime = toDartDatetime(event.utcEnd());
      DateTime currentDateTime = ref.watch(utcNowProvider);

      //Check for event type
      if (eventStartDateTime.isBefore(currentDateTime) &&
          eventEndDateTime.isAfter(currentDateTime)) {
        return EventFilters.ongoing;
      } else if (eventStartDateTime.isAfter(currentDateTime)) {
        return EventFilters.upcoming;
      } else if (eventEndDateTime.isBefore(currentDateTime)) {
        return EventFilters.past;
      }
      return EventFilters.all;
    });
