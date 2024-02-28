import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::reactions');

// ignore_for_file: unused_field

class ReactionManagerNotifier
    extends FamilyNotifier<ReactionManager, ReactionManager> {
  late Stream<void> _listener;
  late StreamSubscription<void> _poller;

  @override
  ReactionManager build(ReactionManager arg) {
    _listener = arg.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        debugPrint('attempting to reload');
        final newManager = await arg.reload();
        debugPrint('manager updated. likes: ${newManager.likesCount()}');
        state = newManager;
      },
      onError: (e, stack) {
        _log.severe('stream errored.', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    // ref.onDispose(() => _poller.cancel());
    return arg;
  }
}
