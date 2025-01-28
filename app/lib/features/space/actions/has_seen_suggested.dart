import 'package:acter/features/room/providers/room_user_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::actions::suggested');

Future<void> markHasSeenSuggested(WidgetRef ref, String roomId) async {
  try {
    final settings = await ref.read(roomUserSettingsProvider(roomId).future);
    await settings.setHasSeenSuggested(true);
  } catch (e, s) {
    _log.severe('Could’t mark $roomId suggested failed', e, s);
  }
}
