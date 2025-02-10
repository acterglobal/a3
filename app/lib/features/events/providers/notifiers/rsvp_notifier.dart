import 'dart:async';

import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, RsvpStatusTag;
import 'package:riverpod/riverpod.dart';

class AsyncRsvpStatusNotifier
    extends AutoDisposeFamilyAsyncNotifier<RsvpStatusTag?, String> {
  late Stream<bool> _listener;

  Future<RsvpStatusTag?> _getMyResponse(Client client, String calEvtId) async {
    final calEvent = await ref.watch(calendarEventProvider(calEvtId).future);
    final rsvp = await calEvent.respondedByMe();
    return switch (rsvp.statusStr()) {
      'yes' => RsvpStatusTag.Yes,
      'no' => RsvpStatusTag.No,
      'maybe' => RsvpStatusTag.Maybe,
      _ => null,
    };
  }

  @override
  Future<RsvpStatusTag?> build(String arg) async {
    final calEvtId = arg;
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeModelObjectsStream(
      calEvtId,
      'rsvp',
    ); // keep it resident in memory
    _listener.forEach((e) async {
      state = AsyncData(await _getMyResponse(client, calEvtId));
    });
    return await _getMyResponse(client, calEvtId);
  }
}
