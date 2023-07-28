import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncNewsListNotifier extends AutoDisposeAsyncNotifier<List<NewsEntry>> {
  late Stream<void> _listener;
  // ignore: unused_field
  late StreamSubscription<void> _poller;

  @override
  Future<List<NewsEntry>> build() async {
    final client = ref.watch(clientProvider)!;
    _listener = client.subscribeStream('news');
    _poller = _listener.listen((e) async {
      debugPrint(' --- - - ----------------- new subscribe received');
      state = await AsyncValue.guard(() => _fetchNews());
    });
    ref.onDispose(() => _poller.cancel());
    return await _fetchNews();
  }

  Future<List<NewsEntry>> _fetchNews() async {
    debugPrint(' -------      refreshing news');
    final client = ref.watch(clientProvider);
    var entries = (await client!.latestNewsEntries(25)).toList();
    return entries;
  }
}
