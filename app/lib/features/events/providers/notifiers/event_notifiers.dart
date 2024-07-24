import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

class EventListNotifier
    extends AutoDisposeAsyncNotifier<List<ffi.CalendarEvent>> {
  late Stream<bool> _listener;

  Future<List<ffi.CalendarEvent>> _getEventList() async {
    final client = ref.read(alwaysClientProvider);
    final events = await client.calendarEvents();
    return events.toList();
  }

  @override
  Future<List<ffi.CalendarEvent>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener =
        client.subscribeStream('calendar'); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(_getEventList);
    });
    return await _getEventList();
  }
}
