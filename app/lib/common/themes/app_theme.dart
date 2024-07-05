import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

@pragma('vm:platform-const')
bool isDesktop = (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
@pragma('vm:platform-const')
final usesNotoEmoji = !(Platform.isWindows ||
    Platform.isMacOS ||
    Platform.isIOS ||
    Platform.isAndroid);

const defaultEmojiFont = 'NotoEmoji';

String? selectEmojiFont() {
  switch (Platform.operatingSystem) {
    case 'ios':
    case 'macos':
      return 'Apple Color Emoji';
    case 'windows':
      return 'Segoe UI Emoji';
    case 'linux':
      return defaultEmojiFont;
    // we fallback to system supported emoji otherwise
    default:
      return null;
  }
}

final emojiFont = selectEmojiFont();
// non-noto-emoji we just fallback to the system fonts.
final List<String>? emojiFallbackFonts =
    emojiFont != null ? [emojiFont!] : null;

class EmojiConfig {
  static TextStyle? emojiTextStyle =
      emojiFont != null ? TextStyle(fontFamily: emojiFont) : null;
  static final checkPlatformCompatibility = emojiFont != defaultEmojiFont;
  static final emojiSizeMax = 32 * ((!kIsWeb && Platform.isIOS) ? 1.30 : 1.0);
}
