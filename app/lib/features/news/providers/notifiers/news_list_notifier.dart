import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, NewsEntry;
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
    _poller = _listener.listen(
      (data) async {
        _log.info('news subscribe received');
        state = await AsyncValue.guard(() async => await _fetchNews(client));
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _fetchNews(client);
  }

  Future<List<NewsEntry>> _fetchNews(Client client) async {
    _log.info('refreshing news');
    return (await client.latestNewsEntries(25)).toList();
  }
}
