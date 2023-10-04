import 'package:acter/features/events/data/repository/calendar_event_repository.dart';
import 'package:acter/features/events/domain/usecases.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendar Events Repository (API) Provider.
final calendarRepositoryProvider = Provider<CalendarEventRepository>(
  (ref) => CalendarRepositoryImpl(ref.watch(clientProvider)!),
);

// Domain Layer Providers.
final getCalendarEventsProvider = Provider<GetCalendarEventsUseCase>(
  (ref) => GetCalendarEventsUseCase(ref.watch(calendarRepositoryProvider)),
);

final getCalendarEventProvider = Provider<GetCalendarEventUseCase>(
  (ref) => GetCalendarEventUseCase(ref.watch(calendarRepositoryProvider)),
);

final spaceCalendarEventsProvider = Provider<GetSpaceCalendarEventsUseCase>(
  (ref) => GetSpaceCalendarEventsUseCase(ref.watch(calendarRepositoryProvider)),
);

final getUpcomingCalendarEventsProvider =
    Provider<GetUpcomingCalendarEventsUseCase>(
  (ref) =>
      GetUpcomingCalendarEventsUseCase(ref.watch(calendarRepositoryProvider)),
);

final getPastCalendarEventsProvider = Provider<GetPastCalendarEventsUseCase>(
  (ref) => GetPastCalendarEventsUseCase(ref.watch(calendarRepositoryProvider)),
);

// Presentation Layer Providers.
final calendarEventsProvider =
    FutureProvider.autoDispose<List<ffi.CalendarEvent>>(
  (ref) => ref.watch(getCalendarEventsProvider).execute(),
);

final calendarEventProvider =
    FutureProvider.family.autoDispose<ffi.CalendarEvent, String>(
  (ref, eventId) => ref.watch(getCalendarEventProvider).execute(eventId),
);

final upcomingEventsProvider =
    FutureProvider.autoDispose<List<ffi.CalendarEvent>>(
  (ref) => ref.watch(getUpcomingCalendarEventsProvider).execute(),
);

final pastEventsProvider = FutureProvider.autoDispose<List<ffi.CalendarEvent>>(
  (ref) => ref.watch(getPastCalendarEventsProvider).execute(),
);

final spaceEventsProvider =
    FutureProvider.family<List<ffi.CalendarEvent>, String>(
  (ref, spaceId) => ref.watch(spaceCalendarEventsProvider).execute(spaceId),
);
