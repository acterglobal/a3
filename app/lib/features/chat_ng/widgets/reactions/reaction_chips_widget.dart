import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ReactionRecord;
import 'package:flutter/material.dart';

class ReactionChipsWidget extends StatelessWidget {
  final List<ReactionItem> reactions;
  final Function(String emoji) onReactionTap;
  final VoidCallback onReactionLongPress;

  const ReactionChipsWidget({
    super.key,
    required this.reactions,
    required this.onReactionTap,
    required this.onReactionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      margin: EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children:
            reactions
                .map(
                  (reaction) => _ReactionChip(
                    emoji: reaction.$1,
                    records: reaction.$2,
                    onTap: () => onReactionTap(reaction.$1),
                    onLongPress: onReactionLongPress,
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final List<ReactionRecord> records;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ReactionChip({
    required this.emoji,
    required this.records,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sentByMe = records.any((x) => x.sentByMe());
    final moreThanOne = records.length > 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Chip(
        padding: EdgeInsets.only(right: moreThanOne ? 6 : 3),
        color: WidgetStatePropertyAll(
          sentByMe
              ? colorScheme.primary.withValues(alpha: 0.25)
              : colorScheme.surface,
        ),
        visualDensity: VisualDensity.compact,
        labelPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                sentByMe
                    ? colorScheme.primary.withValues(alpha: 0.7)
                    : Colors.white12,
          ),
        ),
        avatar: _buildEmojiText(),
        labelStyle: Theme.of(context).textTheme.labelSmall,
        label:
            moreThanOne
                ? Text(
                  records.length.toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                )
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildEmojiText() {
    return Text(
      emoji,
      style: EmojiConfig.emojiTextStyle?.copyWith(fontSize: 14),
    );
  }
}
