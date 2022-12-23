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

import 'package:effektio/common/constants.dart';
import 'package:effektio/widgets/emoji_picker_widget.dart';
import 'package:effektio/widgets/reaction_popup_configuration.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';

typedef StringsCallBack = void Function(String emoji, String messageId);

class EmojiRow extends StatelessWidget {
  EmojiRow({
    Key? key,
    required this.onEmojiTap,
    this.emojiConfiguration,
  }) : super(key: key);

  final StringCallback onEmojiTap;
  final EmojiConfiguration? emojiConfiguration;
  final List<String> _emojiUnicodes = [
    heart,
    faceWithTears,
    astonishedFace,
    disappointedFace,
    angryFace,
  ];

  @override
  Widget build(BuildContext context) {
    final emojiList = emojiConfiguration?.emojiList ?? _emojiUnicodes;
    final size = emojiConfiguration?.size;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 5,
          child: Wrap(
            direction: Axis.horizontal,
            spacing: 5.0,
            children: List.generate(
              emojiList.length,
              (index) => InkWell(
                onTap: () => onEmojiTap(emojiList[index]),
                child: Text(
                  emojiList[index],
                  style: TextStyle(fontSize: size ?? 18),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: IconButton(
            padding: const EdgeInsets.only(bottom: 5.0),
            icon: Icon(
              Icons.add,
              color: Colors.grey.shade600,
              size: size ?? 28,
            ),
            onPressed: () => _showBottomSheet(context),
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        builder: (context) => EmojiPickerWidget(
          onSelected: (emoji) {
            Navigator.pop(context);
            onEmojiTap(emoji);
          },
        ),
      );
}
