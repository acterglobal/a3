import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show TypingEvent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::typing_notice');

class ChatTypingEventStateNotifier extends StateNotifier<TypingEvent?> {
  final Ref ref;
  ChatTypingEventStateNotifier(this.ref) : super(null) {
    configure();
  }

  void configure() async {
    final userAppSetttings = await ref.read(userAppSettingsProvider.future);
    final disabled = userAppSetttings.typingNotice();
    if (disabled != null && !disabled) {
      _log.info('typing event stream started');
      ref.listen<AsyncValue<TypingEvent?>>(chatTypingEventProvider,
          (previous, current) {
        if (current.valueOrNull != null) {
          state = current.requireValue;
        }
      });
    } else {
      _log.info('typing event stream disposed');
      state = null;
    }
  }
}
