import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Bookmarks, Client;
import 'package:riverpod/riverpod.dart';

class BookmarksManagerNotifier extends AsyncNotifier<Bookmarks> {
  late Stream<bool> _listener;

  Future<Bookmarks> _getBookmarkManager(Client client) async {
    return await client.account().bookmarks();
  }

  @override
  Future<Bookmarks> build() async {
    final client = ref.watch(alwaysClientProvider);

    _listener = client.subscribeStream('global.acter.bookmarks');

    _listener.forEach((e) async {
      state = AsyncValue.data(await _getBookmarkManager(client));
    });
    return await _getBookmarkManager(client);
  }
}
