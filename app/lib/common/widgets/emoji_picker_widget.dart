import 'dart:math';

import 'package:acter/common/themes/app_theme.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

class EmojiPickerWidget extends StatelessWidget {
  const EmojiPickerWidget({
    Key? key,
    this.size,
    this.onEmojiSelected,
    this.onBackspacePressed,
    this.withBoarder = false,
  }) : super(key: key);

  final Size? size;
  final bool withBoarder;
  final OnEmojiSelected? onEmojiSelected;
  final OnBackspacePressed? onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    final height =
        size == null ? MediaQuery.of(context).size.height / 3 : size!.height;
    final width =
        size == null ? MediaQuery.of(context).size.width : size!.width;
    final cols = min(width / (EmojiConfig.emojiSizeMax * 2), 12).floor();

    return Container(
      padding: withBoarder
          ? const EdgeInsets.only(top: 10, left: 15, right: 15)
          : null,
      decoration: withBoarder
          ? const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            )
          : null,
      height: height,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            width: 35,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: onEmojiSelected,
              onBackspacePressed: onBackspacePressed,
              config: Config(
                columns: cols,
                emojiTextStyle: EmojiConfig.emojiTextStyle,
                checkPlatformCompatibility:
                    EmojiConfig.checkPlatformCompatibility,
                emojiSizeMax: EmojiConfig.emojiSizeMax,
                initCategory: Category.RECENT,
                bgColor: Theme.of(context).colorScheme.background,
                recentTabBehavior: RecentTabBehavior.RECENT,
                recentsLimit: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
