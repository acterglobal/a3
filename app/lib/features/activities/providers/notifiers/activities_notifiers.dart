import 'dart:async';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/features/activity_ui_showcase/mocks/providers/mock_activities_provider.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Activity;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::activities::notifiers');

// Provider for consecutive grouped activities using records 
typedef RoomActivitiesInfo = ({String roomId, List<Activity> activities});

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

class AllActivitiesNotifier extends AsyncNotifier<List<RoomActivitiesInfo>> {
  final int _limit = 100;
  int _offset = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final List<StreamSubscription> _subscriptions = [];
  final List<String> _allActivityIds = []; // Store all activity IDs for pagination
  bool get hasMore => _hasMoreData;

  @override
  Future<List<RoomActivitiesInfo>> build() async {
    final client = await ref.watch(alwaysClientProvider.future);

    // Clean up previous subscriptions
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    final stream = client.allActivities().subscribeStream();
    final sub = stream.listen(
      (data) async {
        try {
          // Reset pagination state and reload from beginning
          await _initialLoad();
        } catch (e, s) {
          _log.severe('Failed to refresh activities', e, s);
        }
      },
      onError: (e, s) => _log.severe('Room stream error', e, s),
      onDone: () => _log.info('Room stream ended'),
    );
    _subscriptions.add(sub);

    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
    });

    // Reset pagination state for initial load
    return await _initialLoad();
  }

  Future<List<RoomActivitiesInfo>> _initialLoad() async {
    // Reset pagination state
    _offset = 0;
    _hasMoreData = true;
    _isLoadingMore = false;
    _allActivityIds.clear();

    // Load activities
    final groupedActivities = await _loadActivitiesInternal(reset: true);
    state = AsyncValue.data(groupedActivities);
    return groupedActivities;
  }

  Future<void> loadMoreActivities() async {
    // Check if we are already loading or if we have no more data
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      final newGroupedActivities = await _loadActivitiesInternal(reset: false);
      state = AsyncValue.data(newGroupedActivities);
    } catch (e, s) {
      _log.severe('Failed to load more activities', e, s);
      _isLoadingMore = false;
    }
  }

  Future<List<RoomActivitiesInfo>> _loadActivitiesInternal({required bool reset}) async {
    _isLoadingMore = true;
    try {
      final client = await ref.watch(alwaysClientProvider.future);

      // Get activity IDs from the client
      final activityIds = await client.allActivities().getIds(_offset, _limit);
      final activityIdsDartList = asDartStringList(activityIds);

      _offset += _limit;
      _hasMoreData = activityIdsDartList.length == _limit;
      
      if (reset) {
        // Reset: clear all activity IDs and start fresh
        _allActivityIds.clear();
        _allActivityIds.addAll(activityIdsDartList);
      } else {
        // Pagination: add new activity IDs to the list
        _allActivityIds.addAll(activityIdsDartList);
      }
      
      final activities = <Activity>[];
      for (final id in _allActivityIds) {
        final activity = reset 
            ? ref.watch(activityProvider(id)).valueOrNull
            : ref.read(activityProvider(id)).valueOrNull;
        if (activity != null && isActivityTypeSupported(activity.typeStr())) {
          activities.add(activity);
        }
      }

      //  Filter activities to only include those from spaces
      final spaceActivities = activities.where((activity) {
        final roomId = activity.roomIdStr();
        final room = reset 
            ? ref.watch(maybeRoomProvider(roomId)).valueOrNull
            : ref.read(maybeRoomProvider(roomId)).valueOrNull;
        return room?.isSpace() == true;
      }).toList();
      
      // Sort by time descending
      final sortedActivities = spaceActivities..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));

      // Group activities by roomId AND date for better UI organization
      // This creates separate groups when activities are from different rooms or different dates
      final groups = <RoomActivitiesInfo>[];
      
      for (final activity in sortedActivities) {
        final roomId = activity.roomIdStr();
        final activityDate = getActivityDate(activity.originServerTs());
        
        // Check if we can add to the last group (same room AND same date)
        if (groups.isNotEmpty && 
            groups.last.roomId == roomId && 
            getActivityDate(groups.last.activities.first.originServerTs()).isAtSameMomentAs(activityDate)) {
          // Add to existing group: same room and same date
          final lastGroup = groups.last;
          groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
        } else {
          // Create new group: different room OR different date
          groups.add((roomId: roomId, activities: [activity]));
        }
      }
      _isLoadingMore = false;
      return groups;
    } catch (e, s) {
      _log.severe('Failed to load activities', e, s);
      rethrow;
    } 
  }
}
