import 'package:acter/features/chat_ng/actions/toggle_reaction_action.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_chips_widget.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_detail_sheet.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReactionsList extends ConsumerWidget {
  final String roomId;
  final String messageId;
  final TimelineEventItem item;
  const ReactionsList({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactions = ref.watch(messageReactionsProvider(item));
    if (reactions.isEmpty) return const SizedBox.shrink();
    return ReactionChipsWidget(
      reactions: reactions,
      onReactionTap:
          (emoji) => toggleReactionAction(ref, roomId, messageId, emoji),
      onReactionLongPress: () => showReactionsSheet(context, reactions),
    );
  }

  void showReactionsSheet(BuildContext context, List<ReactionItem> reactions) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) =>
              ReactionDetailsSheet(roomId: roomId, reactions: reactions),
    );
  }
}
