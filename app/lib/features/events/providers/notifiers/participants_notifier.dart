import 'dart:async';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Client;
import 'package:riverpod/riverpod.dart';

class AsyncParticipantsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<String>, String> {
  late Stream<bool> _listener;

  Future<List<String>> _getParticipants(Client client, String calEvtId) async {
    final calEvent = await ref.watch(calendarEventProvider(calEvtId).future);
    return asDartStringList(await calEvent.participants());
  }

  @override
  Future<List<String>> build(String arg) async {
    final calEvtId = arg;
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeModelObjectsStream(
      calEvtId,
      'rsvp',
    ); // keep it resident in memory
    _listener.forEach((e) async {
      state = AsyncData(await _getParticipants(client, calEvtId));
    });
    return await _getParticipants(client, calEvtId);
  }
}
