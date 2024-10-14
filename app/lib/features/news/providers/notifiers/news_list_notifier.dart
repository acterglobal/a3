import 'dart:async';

import 'package:acter/features/main/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::news::list_notifier');

class AsyncNewsListNotifier
    extends FamilyAsyncNotifier<List<NewsEntry>, String?> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<NewsEntry>> build(String? arg) async {
    final client = ref.watch(alwaysClientProvider);

    //GET ALL NEWS
    if (arg == null) {
      _listener = client.subscribeStream('news');
    } else {
      //GET SPACE NEWS
      _listener = client.subscribeStream('$arg::news');
    }
    _poller = _listener.listen(
      (data) async {
        _log.info('news subscribe received');
        state = await AsyncValue.guard(() => _fetchNews(client));
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
    //GET ALL NEWS
    if (arg == null) {
      return sortNewsListDscTime(
        (await client.latestNewsEntries(25)).toList(),
      ); // this might throw internally
    } else {
      //GET SPACE NEWS
      final space = await client.space(arg!);
      return sortNewsListDscTime(
        (await space.latestNewsEntries(100)).toList(),
      ); // this might throw internally
    }
  }
}

Future<List<NewsEntry>> sortNewsListDscTime(
  List<NewsEntry> newsList,
) async {
  newsList.sort(
    (a, b) => b.originServerTs().compareTo(a.originServerTs()),
  );
  return newsList;
}
