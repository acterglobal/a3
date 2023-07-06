import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent, Space;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncSpaceEventsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<CalendarEvent>, Space> {
  late Stream<void> _listener;
  Future<List<CalendarEvent>> _getEvents() async {
    return (await arg.calendarEvents()).toList(); // this might throw internally
  }

  @override
  Future<List<CalendarEvent>> build(Space arg) async {
    final client = ref.watch(clientProvider)!;
    final spaceId = arg.getRoomId();
    _listener = client.subscribe('$spaceId::CALENDAR'); // stay up to date
    _listener.forEach((_e) async {
      state = await AsyncValue.guard(() => _getEvents());
    });
    return _getEvents();
  }
}

final spaceEventsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncSpaceEventsNotifier, List<CalendarEvent>, Space>(
  () => AsyncSpaceEventsNotifier(),
);
