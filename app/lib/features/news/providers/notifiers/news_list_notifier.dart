import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
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
    final spaceId = arg;
    final client = await ref.watch(alwaysClientProvider.future);

    //GET ALL NEWS
    if (spaceId == null) {
      _listener = client.subscribeSectionStream('news');
    } else {
      //GET SPACE NEWS
      _listener = client.subscribeRoomSectionStream(spaceId, 'news');
    }
    _poller = _listener.listen(
      (data) async {
        _log.info('news subscribe received');
        state = AsyncData(await _fetchNews(client, spaceId));
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _fetchNews(client, spaceId);
  }

  Future<List<NewsEntry>> _fetchNews(Client client, String? spaceId) async {
    //GET ALL NEWS
    if (spaceId == null) {
      final newsEntries =
          await client.latestNewsEntries(25); // this might throw internally
      return sortNewsListDscTime(newsEntries.toList());
    } else {
      //GET SPACE NEWS
      final space = await client.space(spaceId);
      final newsEntries =
          await space.latestNewsEntries(100); // this might throw internally
      return sortNewsListDscTime(newsEntries.toList());
    }
  }
}

Future<List<NewsEntry>> sortNewsListDscTime(List<NewsEntry> newsList) async {
  newsList.sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
  return newsList;
}
