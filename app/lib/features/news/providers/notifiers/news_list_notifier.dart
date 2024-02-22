import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncNewsListNotifier extends AutoDisposeAsyncNotifier<List<NewsEntry>> {
  late Stream<bool> _listener;
  // ignore: unused_field
  late StreamSubscription<bool> _poller;

  @override
  Future<List<NewsEntry>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream('news'); // keep it resident in memory
    _poller = _listener.listen((e) async {
      debugPrint(' --- - - ----------------- new subscribe received');
      state = await AsyncValue.guard(_fetchNews);
    });
    ref.onDispose(() => _poller.cancel());
    return await _fetchNews();
  }

  Future<List<NewsEntry>> _fetchNews() async {
    debugPrint(' -------      refreshing news');
    final client = ref.read(alwaysClientProvider);
    final entries = (await client.latestNewsEntries(25)).toList();
    return entries;
  }
}
