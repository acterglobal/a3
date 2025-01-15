import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_chips_widget.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_detail_sheet.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::reactions_list');

class ReactionsList extends ConsumerWidget {
  final String roomId;
  final String messageId;
  final RoomEventItem item;
  final bool isNextMessageInGroup;
  const ReactionsList({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.item,
    required this.isNextMessageInGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactions = ref.watch(messageReactionsProvider(item));
    if (reactions.isEmpty) return const SizedBox.shrink();
    return ReactionChipsWidget(
      reactions: reactions,
      onReactionTap: (emoji) => toggleReaction(ref, messageId, emoji),
      onReactionLongPress: () => showReactionsSheet(context, reactions),
    );
  }

  void showReactionsSheet(BuildContext context, List<ReactionItem> reactions) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReactionDetailsSheet(
        roomId: roomId,
        reactions: reactions,
      ),
    );
  }

  Future<void> toggleReaction(
    WidgetRef ref,
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
}
