import 'dart:async';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/features/activity_ui_showcase/mocks/providers/mock_activities_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Activities, Activity, Client;
import 'package:riverpod/riverpod.dart';

class AllActivitiesNotifier extends AsyncNotifier<List<Activity>> {
  final List<StreamSubscription> _subscriptions = [];
  Activities? _activities;

  Future<List<Activity>> _fetchAllActivities(Client client) async {
    _activities?.drop();
    _activities = null; // Prevent double free
    _activities = client.allActivities();
    final activityIds = await _activities?.getIds(0, 200); // adjust as needed
    if (activityIds == null) return [];
    final activities = await Future.wait(
      activityIds.toList().map((id) => client.activity(id.toDartString())),
    );
    return activities.whereType<Activity>().toList();
  }

  @override
  Future<List<Activity>> build() async {
    // if we are in showcase mode, return mock activities
    if (includeShowCases) {
      final mockActivities = ref.watch(mockActivitiesProvider);
      return mockActivities;
    }

    final client = await ref.watch(alwaysClientProvider.future);
    final spaces = ref.watch(spacesProvider);

    // Subscribe to each room's stream
    for (final space in spaces) {
      final roomId = space.getRoomIdStr();
      final stream = client.subscribeRoomStream(roomId);
      final sub = stream.listen(
        (data) async {
          state = AsyncValue.data(await _fetchAllActivities(client));
        },
        onError: (e, s) {},
        onDone: () {},
      );
      _subscriptions.add(sub);
    }

    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _activities?.drop();
      _activities = null; // Prevent double free
    });

    return await _fetchAllActivities(client);
  }
}
