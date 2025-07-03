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
  static const int _pageSize = 20;
  
  final List<StreamSubscription> _subscriptions = [];
  Activities? _activities;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<String>> build() async {
    final client = await ref.watch(alwaysClientProvider.future);
    final spaces = ref.watch(spacesProvider);

    // Subscribe to room streams
    for (final space in spaces) {
      final roomId = space.getRoomIdStr();
      final stream = client.subscribeRoomStream(roomId);
      final sub = stream.listen(
        (data) async {
          try {
            await _refresh(client);
          } catch (e, s) {
            _log.severe('Failed to refresh activities', e, s);
          }
        },
        onError: (e, s) => _log.severe('Room stream error', e, s),
        onDone: () => _log.info('Room stream ended'),
      );
      _subscriptions.add(sub);
    }

    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _activities?.drop();
      _activities = null;
    });

    return await _refresh(client);
  }

  void loadMore() {
    if (!_hasMore || _isLoadingMore) return;
    
    _isLoadingMore = true;
    
    // Run the loading in the background without blocking
    _loadMoreActivities(isLoadMore: true).then((result) {
      _isLoadingMore = false;
      state = AsyncValue.data(result);
    }).catchError((error, stackTrace) {
      _isLoadingMore = false;
      _log.severe('Failed to load more activities', error, stackTrace);
      state = AsyncValue.error(error, stackTrace);
    });
  }

  /// Returns true if more activities can be loaded
  bool get hasMoreData => _hasMore;
  
  /// Returns true if currently loading more data
  bool get isLoadingMore => _isLoadingMore;

  Future<List<String>> _refresh(Client client) async {
    _offset = 0;        
    _hasMore = true;    
    _activities?.drop(); 
    _isLoadingMore = false;
    
    _activities = client.allActivities();
    
    // Load first page of activities
    return await _loadMoreActivities(isLoadMore: false);
  }

  Future<List<String>> _loadMoreActivities({required bool isLoadMore}) async {
    try {
      // Get activities from current offset position
      final activityIds = await _activities?.getIds(_offset, _pageSize);
      
      // Check if we've reached the end
      if (activityIds == null || activityIds.isEmpty) {
        _hasMore = false;
        return isLoadMore ? (state.valueOrNull ?? []) : [];
      }

      final newIds = asDartStringList(activityIds);
      
      _offset += newIds.length;                    // Move offset forward
      _hasMore = newIds.length >= _pageSize;       // Check if more pages exist
      
      final List<String> result = isLoadMore 
          ? [...(state.valueOrNull ?? <String>[]), ...newIds]  // Append to existing
          : newIds;                                     // Replace with new
      
      return result;
    } catch (e, s) {
      _log.severe('Failed to load activities', e, s);
      rethrow;
    }
  }
}
