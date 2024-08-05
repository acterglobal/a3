import 'dart:async';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

class BookmarksManagerNotifier extends AsyncNotifier<ffi.Bookmarks> {
  late Stream<bool> _listener;

  Future<ffi.Bookmarks> _getBookmarkManager() async {
    final account = ref.read(accountProvider);
    return await account.bookmarks();
  }

  @override
  Future<ffi.Bookmarks> build() async {
    final client = ref.watch(alwaysClientProvider);

    _listener = client.subscribeStream('global.acter.bookmarks');

    _listener.forEach((e) async {
      state = await AsyncValue.guard(_getBookmarkManager);
    });
    return await _getBookmarkManager();
  }
}
