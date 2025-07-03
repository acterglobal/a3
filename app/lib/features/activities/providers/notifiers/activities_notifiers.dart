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
  static const int _pageSize = 100;

  final List<StreamSubscription> _subscriptions = [];
  Activities? _activities;
  int _offset = 0;
  bool _hasMore = true;

  @override
  Future<List<String>> build() async {
    final client = await ref.watch(alwaysClientProvider.future);
    final spaces = ref.watch(spacesProvider);

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
    if (!_hasMore) return;

    _loadMoreActivities().then((newList) {
      state = AsyncValue.data(newList);
    }).catchError((error, stackTrace) {
      _log.severe('Failed to load more activities', error, stackTrace);
      state = AsyncValue.error(error, stackTrace);
    });
  }

  bool get hasMoreData => _hasMore;

  Future<List<String>> _refresh(Client client) async {
    _offset = 0;
    _hasMore = true;
    _activities?.drop();
    _activities = client.allActivities();
    return await _loadMoreActivities();
  }

  Future<List<String>> _loadMoreActivities() async {
    final prevList = state.valueOrNull ?? [];
    final newIdsRaw = await _activities?.getIds(_offset, _pageSize);

    if (newIdsRaw == null || newIdsRaw.isEmpty) {
      _hasMore = false;
      return prevList;
    }

    final newIds = asDartStringList(newIdsRaw);
    _offset += newIds.length;
    _hasMore = newIds.length >= _pageSize;

    return [...prevList, ...newIds];
  }
}
