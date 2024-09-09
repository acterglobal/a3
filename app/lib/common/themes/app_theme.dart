import 'dart:io';

import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

@pragma('vm:platform-const')
bool isDesktop = (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
@pragma('vm:platform-const')
final usesNotoEmoji = !(Platform.isWindows ||
    Platform.isMacOS ||
    Platform.isIOS ||
    Platform.isAndroid);

const defaultEmojiFont = 'NotoEmoji';

String? selectEmojiFont() {
  return switch (Platform.operatingSystem) {
    'ios' || 'macos' => 'Apple Color Emoji',
    'windows' => 'Segoe UI Emoji',
    'linux' => defaultEmojiFont,
    // we fallback to system supported emoji otherwise
    _ => null,
  };
}

final emojiFont = selectEmojiFont();
// non-noto-emoji we just fallback to the system fonts.
final List<String>? emojiFallbackFonts = emojiFont.map((p0) => [p0]);

class EmojiConfig {
  static TextStyle? emojiTextStyle =
      emojiFont.map((p0) => TextStyle(fontFamily: p0));
  static final checkPlatformCompatibility = emojiFont != defaultEmojiFont;
  static final emojiSizeMax = 32 * ((!kIsWeb && Platform.isIOS) ? 1.30 : 1.0);
}
