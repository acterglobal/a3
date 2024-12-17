import 'dart:async';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Account, ActerUserAppSettings;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::app_settings_notifier');

class UserAppSettingsNotifier
    extends AutoDisposeAsyncNotifier<ActerUserAppSettings> {
  late Stream<bool> _listener;
  late StreamSubscription<bool> _poller;

  Future<ActerUserAppSettings> _getSettings(Account account) async {
    return await account.acterAppSettings();
  }

  @override
  Future<ActerUserAppSettings> build() async {
    final account = ref.watch(accountProvider);
    _listener = account.subscribeAppSettingsStream();
    _poller = _listener.listen(
      (data) async {
        // refresh on update
        state = AsyncData(await _getSettings(account));
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return await _getSettings(account);
  }
}
