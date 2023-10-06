import 'package:acter/features/events/application/events/create_event_controller.dart';
import 'package:acter/features/events/application/events/edit_event_controller.dart';
import 'package:acter/features/events/application/events/event_list_controller.dart';
import 'package:acter/features/events/application/events/event_view_controller.dart';
import 'package:acter/features/events/application/events/past_list_controller.dart';
import 'package:acter/features/events/application/events/redact_event_controller.dart';
import 'package:acter/features/events/application/events/space_events_controller.dart';
import 'package:acter/features/events/application/events/upcoming_list_controller.dart';
import 'package:acter/features/events/application/rsvp/count_status_controller.dart';
import 'package:acter/features/events/application/rsvp/rsvp_count_controller.dart';
import 'package:acter/features/events/application/rsvp/rsvp_entries_controller.dart';
import 'package:acter/features/events/application/rsvp/rsvp_status_controller.dart';
import 'package:acter/features/events/application/rsvp/rsvp_users_controller.dart';
import 'package:acter/features/events/application/rsvp/set_rsvp_controller.dart';
import 'package:acter/features/events/data/repository/calendar_event_repository.dart';
import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data Dependencies.
///
final calendarRepositoryProvider = Provider<EventRepositoryInterface>(
  (ref) {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    return CalendarEventRepository(client);
  },
);

/// Application Dependencies.
///
final calendarEventsProvider = StateNotifierProvider.autoDispose<
    CalendarEventListController, AsyncValue<List<ffi.CalendarEvent>>>(
  (ref) => CalendarEventListController(ref.watch(calendarRepositoryProvider)),
);

final calendarEventProvider = StateNotifierProvider.family.autoDispose<
    CalendarEventViewController, AsyncValue<ffi.CalendarEvent>, String>(
  (ref, eventId) => CalendarEventViewController(
    ref.watch(calendarRepositoryProvider),
    eventId,
  ),
);

final upcomingEventsProvider = StateNotifierProvider.autoDispose<
    UpcomingEventsListController, AsyncValue<List<ffi.CalendarEvent>>>(
  (ref) => UpcomingEventsListController(ref.watch(calendarRepositoryProvider)),
);

final pastEventsProvider = StateNotifierProvider.autoDispose<
    PastEventsListController, AsyncValue<List<ffi.CalendarEvent>>>(
  (ref) => PastEventsListController(ref.watch(calendarRepositoryProvider)),
);

final spaceEventsProvider = StateNotifierProvider.family.autoDispose<
    SpaceEventsListController, AsyncValue<List<ffi.CalendarEvent>>, String>(
  (ref, spaceId) =>
      SpaceEventsListController(ref.watch(calendarRepositoryProvider), spaceId),
);

final createEventProvider = StateNotifierProvider.autoDispose<
    CreateEventController, AsyncValue<ffi.CalendarEvent?>>(
  (ref) => CreateEventController(
    ref.watch(calendarRepositoryProvider),
  ),
);

final editEventProvider = StateNotifierProvider.autoDispose<EditEventController,
    AsyncValue<ffi.CalendarEvent?>>(
  (ref) => EditEventController(
    ref.watch(calendarRepositoryProvider),
  ),
);

final redactEventProvider =
    StateNotifierProvider.autoDispose<RedactEventController, AsyncValue<bool?>>(
  (ref) => RedactEventController(
    ref.watch(calendarRepositoryProvider),
  ),
);

final rsvpStatusProvider = StateNotifierProvider.family
    .autoDispose<RsvpStatusController, AsyncValue<String>, String>(
  (ref, calendarId) => RsvpStatusController(
    ref.watch(calendarRepositoryProvider),
    calendarId,
  ),
);

final setRsvpProvider = StateNotifierProvider.family
    .autoDispose<SetRsvpController, AsyncValue<String?>, String>(
  (ref, calendarId) =>
      SetRsvpController(ref.watch(calendarRepositoryProvider), calendarId),
);

final rsvpCountProvider = StateNotifierProvider.family
    .autoDispose<RsvpCountController, AsyncValue<int>, String>(
  (ref, calendarId) =>
      RsvpCountController(ref.watch(calendarRepositoryProvider), calendarId),
);

final rsvpEntriesProvider = StateNotifierProvider.family
    .autoDispose<RsvpEntriesController, AsyncValue<List<ffi.Rsvp>?>, String>(
  (ref, calendarId) =>
      RsvpEntriesController(ref.watch(calendarRepositoryProvider), calendarId),
);

final rsvpUsersProvider = StateNotifierProvider.family
    .autoDispose<RsvpUsersController, AsyncValue<List<String>>, String>(
  (ref, calendarId) =>
      RsvpUsersController(ref.watch(calendarRepositoryProvider), calendarId),
);

final rsvpCountAtStatusProvider = StateNotifierProvider.family
    .autoDispose<CountStatusController, AsyncValue<int?>, String>(
  (ref, calendarId) =>
      CountStatusController(ref.watch(calendarRepositoryProvider), calendarId),
);

final rsvpUsersAtStatusProvider = StateNotifierProvider.family
    .autoDispose<RsvpUsersController, AsyncValue<List<String>?>, String>(
  (ref, calendarId) =>
      RsvpUsersController(ref.watch(calendarRepositoryProvider), calendarId),
);
