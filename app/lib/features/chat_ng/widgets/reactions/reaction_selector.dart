import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/features/chat_ng/actions/toggle_reaction_action.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReactionSelector extends ConsumerWidget {
  final double? size;
  final String messageId;
  final String roomId;
  final bool isMe;

  const ReactionSelector({
    super.key,
    required this.isMe,
    required this.messageId,
    required this.roomId,
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: EdgeInsets.only(
          bottom: 4,
          left: isMe ? 0 : 8,
          right: isMe ? 8 : 0,
        ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        ),
        child: _buildEmojiRow(context, ref),
      ),
    );
  }

  Widget _buildEmojiRow(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          direction: Axis.horizontal,
          spacing: 10.0,
          children: [
            ..._buildEmojiButtons(context, ref),
            _buildMoreButton(context, ref),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildEmojiButtons(BuildContext context, WidgetRef ref) {
    return [
      heart,
      thumbsUp,
      prayHands,
      faceWithTears,
      clappingHands,
      raisedHands,
      astonishedFace,
    ].map((emoji) => _buildEmojiButton(emoji, context, ref)).toList();
  }

  Widget _buildEmojiButton(String emoji, BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        await toggleReactionAction(ref, roomId, messageId, emoji);
        if (context.mounted) Navigator.pop(context);
      },
      child: Text(
        emoji,
        style: (EmojiConfig.emojiTextStyle ?? const TextStyle())
            .copyWith(fontSize: size ?? 28),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showEmojiPicker(context, ref),
      child: const Padding(
        padding: EdgeInsets.only(top: 3),
        child: Icon(
          Atlas.dots_horizontal_thin,
          size: 28,
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      enableDrag: false,
      builder: (context) => EmojiPickerWidget(
        withBoarder: true,
        onEmojiSelected: (category, emoji) async {
          await toggleReactionAction(ref, roomId, messageId, emoji.emoji);
          if (context.mounted) {
            // we have overlays opened, dismiss both of them
            Navigator.pop(context);
            Navigator.pop(context);
          }
        },
        onClosePicker: () => Navigator.pop(context),
      ),
    );
  }
}
