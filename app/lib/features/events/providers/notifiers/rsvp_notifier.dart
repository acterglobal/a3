import 'dart:async';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

class AsyncRsvpStatusNotifier
    extends AutoDisposeFamilyAsyncNotifier<ffi.OptionRsvpStatus, String> {
  late Stream<bool> _listener;

  Future<ffi.OptionRsvpStatus> _getMyResponse() async {
    final client = ref.read(alwaysClientProvider);
    final calEvent = await client.waitForCalendarEvent(arg, null);
    return await calEvent.respondedByMe();
  }

  @override
  Future<ffi.OptionRsvpStatus> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener =
        client.subscribeStream('$arg::rsvp'); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(_getMyResponse);
    });
    return await _getMyResponse();
  }
}
