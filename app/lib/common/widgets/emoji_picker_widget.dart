import 'dart:io';
import 'dart:math';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class EmojiPickerWidget extends StatelessWidget {
  const EmojiPickerWidget({
    Key? key,
    this.size,
    this.onEmojiSelected,
    this.onBackspacePressed,
  }) : super(key: key);

  final Size? size;
  final OnEmojiSelected? onEmojiSelected;
  final OnBackspacePressed? onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    final emojiSize = 32 * ((!kIsWeb && Platform.isIOS) ? 1.30 : 1.0);
    final height =
        size == null ? MediaQuery.of(context).size.height / 3 : size!.height;
    final width =
        size == null ? MediaQuery.of(context).size.width : size!.width;
    final cols = min(width / (emojiSize * 2), 12).floor();

    return Container(
      padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                emojiTextStyle: GoogleFonts.notoColorEmoji(),
                checkPlatformCompatibility: false,
                emojiSizeMax: emojiSize,
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
