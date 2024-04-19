import 'package:acter/common/themes/colors/color_scheme.dart';
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

extension CustomColorScheme on ColorScheme {
  Color get primary => const Color(0xFF9CCAFF);
  Color get tertiary => const Color(0xFFFFC333);
  Color get tertiary3 => const Color(0xFF3AE3E0);
  Color get neutral => const Color(0xFF121212);
  Color get neutral2 => const Color(0xFF2F2F2F);
  Color get neutral3 => const Color(0xFF5D5D5D);
  Color get neutral4 => const Color(0xFF898989);
  Color get neutral5 => const Color(0xFFB7B7B7);
  Color get neutral6 => const Color(0xFFE5E5E5);

  // brand
  Color get textHighlight => secondary;
  Color get textButtonColor => whiteColor;
  Color get textColor => whiteColor;

  // states
  Color get success => secondary;

  // specific widgets
  Color get badgeUnread => secondary;
  Color get badgeImportant => yellowColor;
  Color get badgeUrgent => const Color(0xFF93000A);

  // tasks
  Color get tasksBG => primary;
  Color get tasksFG => primaryContainer;
  Color get taskOverdueBG => errorContainer;
  Color get taskOverdueFG => error;
}
