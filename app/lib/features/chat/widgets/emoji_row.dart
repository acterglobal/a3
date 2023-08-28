/*
 * Copyright (c) 2022 Simform Solutions
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
import 'package:atlas_icons/atlas_icons.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';

typedef StringsCallBack = void Function(String emoji, String messageId);

class EmojiRow extends StatelessWidget {
  final double? size;
  EmojiRow({
    Key? key,
    required this.onEmojiTap,
    this.size,
  }) : super(key: key);

  final StringCallback onEmojiTap;
  final List<String> _emojiUnicodes = [
    heart,
    thumbsUp,
    prayHands,
    faceWithTears,
    clappingHands,
    raisedHands,
    astonishedFace,
  ];

  @override
  Widget build(BuildContext context) {
    final emojiList = _emojiUnicodes;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          direction: Axis.horizontal,
          spacing: 5.0,
          children: [
            for (var emoji in emojiList)
              InkWell(
                onTap: () => onEmojiTap(emoji),
                child: Text(
                  emoji,
                  style:
                      EmojiConfig.emojiTextStyle.copyWith(fontSize: size ?? 18),
                ),
              ),
            InkWell(
              onTap: () => _showBottomSheet(context),
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  Atlas.dots_horizontal_thin,
                  color: Theme.of(context).colorScheme.neutral5,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        builder: (context) => EmojiPickerWidget(
          withBoarder: true,
          onEmojiSelected: (category, emoji) {
            Navigator.pop(context);
            onEmojiTap(emoji.emoji);
          },
        ),
      );
}
