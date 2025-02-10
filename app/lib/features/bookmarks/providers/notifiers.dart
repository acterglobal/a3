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
    final client = await ref.watch(alwaysClientProvider.future);

    _listener = client.subscribeEventTypeStream('global.acter.bookmarks');

    _listener.forEach((e) async {
      state = await AsyncValue.guard(
        () async => await _getBookmarkManager(client),
      );
    });
    return await _getBookmarkManager(client);
  }
}
