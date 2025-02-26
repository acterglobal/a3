import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Story;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::stories::list_notifier');

class AsyncStoryListNotifier extends FamilyAsyncNotifier<List<Story>, String?> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  @override
  Future<List<Story>> build(String? arg) async {
    final spaceId = arg;
    final client = await ref.watch(alwaysClientProvider.future);

    //GET ALL STORIES
    if (spaceId == null) {
      _listener = client.subscribeSectionStream('stories');
    } else {
      //GET SPACE STORIES
      _listener = client.subscribeRoomSectionStream(spaceId, 'stories');
    }
    _poller = _listener.listen(
      (data) async {
        _log.info('stories subscribe received');
        state = AsyncValue.data(await _fetchStories(client, spaceId));
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _fetchStories(client, spaceId);
  }

  Future<List<Story>> _fetchStories(Client client, String? spaceId) async {
    //GET ALL STORIES
    if (spaceId == null) {
      final storyEntries =
          await client.latestStories(25); // this might throw internally
      return sortNewsListDscTime(storyEntries.toList());
    } else {
      //GET SPACE STORIES
      final space = await client.space(spaceId);
      final storyEntries =
          await space.latestStories(100); // this might throw internally
      return sortNewsListDscTime(storyEntries.toList());
    }
  }
}

Future<List<Story>> sortNewsListDscTime(List<Story> storyList) async {
  storyList.sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
  return storyList;
}
