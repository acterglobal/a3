import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::actions::suggested');

Future<void> markHasSeenSuggested(WidgetRef ref, String roomId) async {
  final room = ref.read(maybeRoomProvider(roomId));
  if (room == null) {
    _log.warning('Could’t mark $roomId suggested as seen. Room not found');
    return;
  }
  try {
    await room.setUserHasSeenSuggested(true);
  } catch (e, s) {
    _log.severe('Could’t mark $roomId suggested failed', e, s);
  }
}
