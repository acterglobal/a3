import 'dart:async';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserAppSettingsNotifier
    extends AutoDisposeAsyncNotifier<ActerUserAppSettings> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<ActerUserAppSettings> _getSettings() async {
    return await ref.read(accountProvider).acterAppSettings();
  }

  @override
  Future<ActerUserAppSettings> build() async {
    final account = ref.watch(accountProvider);
    _listener = account.subscribeAppSettingsStream();
    _poller = _listener.listen((e) async {
      // refresh on update
      state = await AsyncValue.guard(_getSettings);
    });
    ref.onDispose(() => _poller.cancel());
    return await _getSettings();
  }
}
