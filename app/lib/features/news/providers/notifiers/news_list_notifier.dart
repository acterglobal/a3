import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::news::list_notifier');

class AsyncNewsListNotifier extends AutoDisposeAsyncNotifier<List<NewsEntry>> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<NewsEntry>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('news'); // keep it resident in memory
    _poller = _listener.listen((e) async {
      _log.info('new subscribe received');
      state = await AsyncValue.guard(_fetchNews);
    });
    ref.onDispose(() => _poller.cancel());
    return await _fetchNews();
  }

  Future<List<NewsEntry>> _fetchNews() async {
    _log.info('refreshing news');
    final client = ref.read(alwaysClientProvider);
    final entries = (await client.latestNewsEntries(25)).toList();
    return entries;
  }
}
