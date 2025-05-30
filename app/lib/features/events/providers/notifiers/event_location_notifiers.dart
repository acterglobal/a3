import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show EventLocationInfo, Client;
import 'package:riverpod/riverpod.dart';

class AsyncEventLocationsNotifier extends AutoDisposeFamilyAsyncNotifier<List<EventLocationInfo>, String> {
  late Stream<bool> _listener;

  Future<List<EventLocationInfo>> _getLocations(Client client, String calEvtId) async {
    final event = await client.waitForCalendarEvent(calEvtId, null);
    final locations = event.locations();
    return locations.toList();
  }

  @override
  Future<List<EventLocationInfo>> build(String calEvtId) async {
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeModelStream(calEvtId);
    _listener.forEach((e) async {
      state = AsyncValue.data(await _getLocations(client, calEvtId));
    });
    return await _getLocations(client, calEvtId);
  }
}

class AsyncPhysicalEventLocationsNotifier extends AutoDisposeFamilyAsyncNotifier<List<EventLocationInfo>, String> {
  late Stream<bool> _listener;

  Future<List<EventLocationInfo>> _getLocations(Client client, String calEvtId) async {
    final event = await client.waitForCalendarEvent(calEvtId, null);
    final locations = event.physicalLocations();
    return locations.toList();
  }

  @override
  Future<List<EventLocationInfo>> build(String calEvtId) async {
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeModelStream(calEvtId);
    _listener.forEach((e) async {
      state = AsyncValue.data(await _getLocations(client, calEvtId));
    });
    return await _getLocations(client, calEvtId);
  }
}

class AsyncVirtualEventLocationsNotifier extends AutoDisposeFamilyAsyncNotifier<List<EventLocationInfo>, String> {
  late Stream<bool> _listener;

  Future<List<EventLocationInfo>> _getLocations(Client client, String calEvtId) async {
    final event = await client.waitForCalendarEvent(calEvtId, null);
    final locations = event.virtualLocations();
    return locations.toList();
  }

  @override
  Future<List<EventLocationInfo>> build(String calEvtId) async {
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeModelStream(calEvtId);
    _listener.forEach((e) async {
      state = AsyncValue.data(await _getLocations(client, calEvtId));
    });
    return await _getLocations(client, calEvtId);
  }
}
