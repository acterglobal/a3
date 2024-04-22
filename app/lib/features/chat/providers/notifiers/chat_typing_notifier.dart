import 'dart:async';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::typing_notice');

class ChatTypingEventStateNotifier extends StateNotifier<TypingEvent?> {
  final Ref ref;
  ChatTypingEventStateNotifier(this.ref) : super(null) {
    _init();
  }
  StreamSubscription<TypingEvent?>? _poller;
  void _init() async {
    final userAppSetttings = await ref.read(userAppSettingsProvider.future);
    final enabled = userAppSetttings.typingNotice();
    final client = ref.read(alwaysClientProvider);
    _poller = client.typingEventRx()!.listen((e) {
      state = e;
    });
    if (enabled == null) {
      // default settings not available, enable it automatically.
      final updater = userAppSetttings.updateBuilder();
      updater.typingNotice(true);
      await updater.send();
      configure(true);
    } else {
      configure(enabled);
    }
  }

  void configure(bool enabled) async {
    if (enabled) {
      _log.info('listening to typing event stream');
      _poller?.resume();
    } else {
      _log.info('defer listening typing event stream');
      _poller?.pause();
      state = null;
    }
  }
}
