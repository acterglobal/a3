import 'dart:async';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/features/activity_ui_showcase/mocks/providers/mock_activities_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Activities, Activity, Client;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::activities::notifiers');

// Single Activity Notifier 
class AsyncActivityNotifier extends FamilyAsyncNotifier<Activity?, String> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  FutureOr<Activity?> build(String arg) async {
    final activityId = arg;

    // if we are in showcase mode, return mock activity
    if (includeShowCases) {
      final mockActivity = ref.watch(mockActivityProvider(activityId));
      if (mockActivity != null) {
        return mockActivity;
      }
    }

    // otherwise, get the activity from the client
    final client = await ref.watch(alwaysClientProvider.future);
    _listener = client.subscribeModelStream(
      activityId,
    ); // keep it resident in memory
    _poller = _listener.listen(
      (data) async {
        try {
          state = AsyncValue.data(await client.activity(activityId));
        } catch (e, s) {
          _log.severe('activity stream update failed', e, s);
          state = AsyncValue.error(e, s);
        }
      },
      onError: (e, s) {
        _log.severe('activity stream errored', e, s);
        state = AsyncValue.error(e, s);
      },
      onDone: () {
        _log.info('activity stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await client.activity(activityId);
  }
}

class AllActivitiesNotifier extends AsyncNotifier<List<String>> {
  final List<StreamSubscription> _subscriptions = [];
  Activities? _activities;
  
  // Pagination state
  static const int _pageSize = 100;
  int _currentOffset = 0;
  bool _hasMoreData = true;

  Future<List<String>> _fetchAllActivities(Client client, {bool loadMore = false}) async {
    if (!loadMore) {
      // Reset pagination for initial load
      _currentOffset = 0;
      _hasMoreData = true;
      _activities?.drop();
      _activities = null;
      _activities = client.allActivities();
    }

    if (!_hasMoreData) {
      return state.valueOrNull ?? [];
    }

    try {
      // Ensure we have an Activities object
      _activities ??= client.allActivities();

      final activityIds = await _activities?.getIds(_currentOffset, _pageSize);
      
      if (activityIds == null || activityIds.isEmpty) {
        _hasMoreData = false;
        return state.valueOrNull ?? [];
      }

      final newActivityIds = asDartStringList(activityIds);
      
      // Update pagination state
      _currentOffset += activityIds.length;
      _hasMoreData = activityIds.length >= _pageSize;

      List<String> result;
      if (loadMore) {
        // Append new activities to existing list
        final currentActivities = state.valueOrNull ?? [];
        result = [...currentActivities, ...newActivityIds];
      } else {
        // Return new activities for initial load
        result = newActivityIds;
      }

      return result;
    } catch (e, s) {
      _log.severe('Failed to fetch activities', e, s);
      rethrow;
    }
  }

  // Method to load more activities (called when scrolling)
  Future<void> loadMore() async {
    if (!_hasMoreData) return;

    try {
      final client = await ref.read(alwaysClientProvider.future);
      final newActivities = await _fetchAllActivities(client, loadMore: true);
      state = AsyncValue.data(newActivities);
    } catch (e, s) {
      _log.severe('Failed to load more activities', e, s);
      state = AsyncValue.error(e, s);
    }
  }

  // Getter to check if more data can be loaded
  bool get hasMoreData => _hasMoreData;

  @override
  Future<List<String>> build() async {
    final client = await ref.watch(alwaysClientProvider.future);
    final spaces = ref.watch(spacesProvider);

    // Subscribe to each room's stream
    for (final space in spaces) {
      final roomId = space.getRoomIdStr();
      final stream = client.subscribeRoomStream(roomId);
      final sub = stream.listen(
        (data) async {
          try {
            state = AsyncValue.data(await _fetchAllActivities(client));
          } catch (e, s) {
            _log.severe('Failed to refresh activities', e, s);
          }
        },
        onError: (e, s) {
          _log.severe('Room stream error', e, s);
        },
        onDone: () {
          _log.info('Room stream ended');
        },
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

// Create a separate StateNotifier for loading state management
class LoadingStateNotifier extends StateNotifier<bool> {
  LoadingStateNotifier() : super(false);

  void setLoading(bool loading) {
    state = loading;
  }
}

