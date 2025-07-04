import 'dart:async';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/features/activity_ui_showcase/mocks/providers/mock_activities_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Activity;
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
  final int _limit = 10;
  int _offset = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final List<StreamSubscription> _subscriptions = [];

  bool get hasMore => _hasMoreData;

  @override
  Future<List<String>> build() async {
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

  Future<List<String>> _initialLoad() async {
    // Reset pagination state
    _offset = 0;
    _hasMoreData = true;
    _isLoadingMore = false;

    // Load activities
    final activityIds = await _loadActivitiesInternal(reset: true);
    state = AsyncValue.data(activityIds);
    return activityIds;
  }

  Future<void> loadMoreActivities() async {
    // Check if we are already loading or if we have no more data
    if (_isLoadingMore || !_hasMoreData) return;

    // Load more activities
    final newActivities = await _loadActivitiesInternal(reset: false);
    state = AsyncValue.data(newActivities);
  }

  Future<List<String>> _loadActivitiesInternal({required bool reset}) async {
    _isLoadingMore = true;

    try {
      final client = await ref.watch(alwaysClientProvider.future);

      final activityIds = await client.allActivities().getIds(_offset, _limit);
      final activityIdsDartList = asDartStringList(activityIds);

      _offset += _limit;
      _hasMoreData = activityIdsDartList.length == _limit;

      if (reset) {
        // Return new activities only if we are resetting
        return activityIdsDartList;
      } else {
        // Merge with existing data
        final existingData = state.valueOrNull ?? [];
        return [...existingData, ...activityIdsDartList];
      }
    } catch (e, s) {
      _log.severe('Failed to load activities', e, s);
      rethrow;
    } finally {
      // Reset loading state to false
      _isLoadingMore = false;
    }
  }
}
