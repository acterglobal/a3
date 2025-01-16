/*
 * Copyright (c) 2024, Acter Global, (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::reactions_selector_row');

class ReactionSelectorRow extends ConsumerWidget {
  final double? size;
  final String messageId;
  final String roomId;
  final bool isUser;

  const ReactionSelectorRow({
    super.key,
    required this.isUser,
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
          left: isUser ? 0 : 8,
          right: isUser ? 8 : 0,
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
        await toggleReaction(ref, messageId, emoji);
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

  void _showEmojiPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      enableDrag: false,
      builder: (context) => EmojiPickerWidget(
        withBoarder: true,
        onEmojiSelected: (category, emoji) async {
          await toggleReaction(ref, messageId, emoji.emoji);
          if (context.mounted) Navigator.pop(context);
        },
        onClosePicker: () => Navigator.pop(context),
      ),
    );
  }
}
