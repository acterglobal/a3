import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

class AsyncRsvpStatusNotifier
    extends AutoDisposeFamilyAsyncNotifier<ffi.RsvpStatusTag?, String> {
  late Stream<bool> _listener;

  Future<ffi.RsvpStatusTag?> _getMyResponse() async {
    final client = ref.read(alwaysClientProvider);
    final calEvent = await client.waitForCalendarEvent(arg, null);
    final rsvp = await calEvent.respondedByMe();
    return switch (rsvp.statusStr()) {
      'yes' => ffi.RsvpStatusTag.Yes,
      'no' => ffi.RsvpStatusTag.No,
      'maybe' => ffi.RsvpStatusTag.Maybe,
      _ => null,
    };
  }

  @override
  Future<ffi.RsvpStatusTag?> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener =
        client.subscribeStream('$arg::rsvp'); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(_getMyResponse);
    });
    return await _getMyResponse();
  }
}
