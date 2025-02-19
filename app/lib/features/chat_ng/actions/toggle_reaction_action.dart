import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::toggle_reaction');

Future<void> toggleReactionAction(
  WidgetRef ref,
  String roomId,
  String uniqueId,
  String emoji,
) async {
  try {
    final stream = await ref.read(timelineStreamProvider(roomId).future);
    await stream.toggleReaction(uniqueId, emoji);
  } catch (e, s) {
    _log.severe('Reaction toggle failed', e, s);
  }
}
