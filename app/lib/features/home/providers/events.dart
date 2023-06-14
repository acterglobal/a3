import 'dart:core';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: how to get informed about updates!?!
  final calendarEvents = await client.calendarEvents();
  return calendarEvents.toList();
});
