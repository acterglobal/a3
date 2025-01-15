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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.secondaryContainer),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Wrap(
          direction: Axis.horizontal,
          spacing: 3,
          runSpacing: 3,
          children: reactions
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
        padding: moreThanOne
            ? const EdgeInsets.only(right: 4)
            : const EdgeInsets.symmetric(horizontal: 2),
        color: WidgetStatePropertyAll(
          sentByMe ? colorScheme.secondaryContainer : colorScheme.surface,
        ),
        visualDensity: VisualDensity.compact,
        labelPadding:
            sentByMe ? EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
        shape: const StadiumBorder(side: BorderSide(color: Colors.transparent)),
        avatar: moreThanOne ? _buildEmojiText() : null,
        label: moreThanOne
            ? Text(
                records.length.toString(),
                style: Theme.of(context).textTheme.labelSmall,
              )
            : _buildEmojiText(),
      ),
    );
  }

  Widget _buildEmojiText() {
    return Text(emoji, style: EmojiConfig.emojiTextStyle);
  }
}
