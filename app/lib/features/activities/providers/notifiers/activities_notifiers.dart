import 'dart:async';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Activities, Activity, Client;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::activity_notifiers');

class AsyncSpaceActivitiesNotifier
    extends FamilyAsyncNotifier<List<String>, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;
  Activities? _activities;

  Future<List<String>> _getSpaceActivities(Client client) async {
    // Clean up previous activities if they exist
    _activities?.drop();

    // Get new activities for the space
    _activities = client.activitiesForRoom(arg);
    final activitiesIds = await _activities?.getIds(0, 100);
    if (activitiesIds == null) return [];
    return asDartStringList(activitiesIds);
  }

  @override
  Future<List<String>> build(String arg) async {
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeRoomStream(arg);
    _poller = _listener.listen(
      (data) async {
        _log.info('space $arg : activities');
        state = await AsyncValue.guard(
          () async => await _getSpaceActivities(client),
        );
      },
      onError: (e, s) {
        _log.severe('space activities stream errored', e, s);
      },
      onDone: () {
        _log.info('space activities stream ended');
      },
    );

    ref.onDispose(() {
      _poller.cancel();
      _activities?.drop();
    });

    return await _getSpaceActivities(client);
  }
}

class AsyncActivityNotifier extends FamilyAsyncNotifier<Activity?, String> {
  Activity? _activity;

  Future<Activity?> _getActivity(Client client) async {
    // Clean up previous activity if it exists
    _activity?.drop();

    _activity = await client.activity(arg);
    // Get activity based on id
    return _activity;
  }

  @override
  Future<Activity?> build(String arg) async {
    final client = await ref.watch(alwaysClientProvider.future);

    ref.onDispose(() {
      _activity?.drop();
    });

    return await _getActivity(client);
  }
}
