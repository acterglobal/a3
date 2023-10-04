import 'package:acter/features/events/application/create_event_controller.dart';
import 'package:acter/features/events/application/edit_event_controller.dart';
import 'package:acter/features/events/application/event_list_controller.dart';
import 'package:acter/features/events/application/event_view_controller.dart';
import 'package:acter/features/events/application/past_list_controller.dart';
import 'package:acter/features/events/application/redact_event_controller.dart';
import 'package:acter/features/events/application/space_events_controller.dart';
import 'package:acter/features/events/application/upcoming_list_controller.dart';
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
