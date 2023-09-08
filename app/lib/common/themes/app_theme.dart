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

AppTheme currentTheme = AppTheme();

extension CustomColorScheme on ColorScheme {
  Color get success => const Color(0xFF67A24A);
  Color get tertiary2 => const Color(0xFFFFC333);
  Color get tertiary3 => const Color(0xFF3AE3E0);
  Color get neutral => const Color(0xFF121212);
  Color get neutral2 => const Color(0xFF2F2F2F);
  Color get neutral3 => const Color(0xFF5D5D5D);
  Color get neutral4 => const Color(0xFF898989);
  Color get neutral5 => const Color(0xFFB7B7B7);
  Color get neutral6 => const Color(0xFFE5E5E5);
  Color get m3Primary => const Color(0xFFD0BCFF);

  Color get badgeUnread => const Color(0xFF67A24A);
  Color get badgeImportant => const Color(0xFFFFC333);
  Color get badgeUrgent => const Color(0xFF93000A);
}

class AppTheme {
  static const brandColorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: Color(0xFF9CCAFF),
    onPrimary: Color(0xFF003257),
    primaryContainer: Color(0xFF00497B),
    onPrimaryContainer: Color(0xFFD0E4FF),
    secondary: Color(0xFF9ACBFF),
    onSecondary: Color(0xFF003355),
    secondaryContainer: Color(0xFF004A79),
    onSecondaryContainer: Color(0xFFD0E4FF),
    tertiary: Color(0xFFFFB77B),
    onTertiary: Color(0xFF4D2700),
    tertiaryContainer: Color(0xFF6D3A00),
    onTertiaryContainer: Color(0xFFFFDCC2),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    onError: Color(0xFF690005),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF001B3D),
    onBackground: Color(0xFFD6E3FF),
    surface: Color(0xFF001B3D),
    onSurface: Color(0xFFD6E3FF),
    surfaceVariant: Color(0xFF42474E),
    onSurfaceVariant: Color(0xFFC2C7CF),
    outline: Color(0xFF8C9199),
    onInverseSurface: Color(0xFF001B3D),
    inverseSurface: Color(0xFFD6E3FF),
    inversePrimary: Color(0xFF0062A1),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF9CCAFF),
    outlineVariant: Color(0xFF42474E),
    scrim: Color(0xFF000000),
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.center,
    colors: <Color>[
      Color(0xFF001B3D),
      Color(0xFF121212),
    ],
  );

  static MaterialStateProperty<Color?> dangerState =
      MaterialStateProperty.all(brandColorScheme.error);
  static ThemeData get theme {
    return ThemeData(
      fontFamily: 'Inter',
      fontFamilyFallback: emojiFallbackFonts,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w300,
          decorationThickness: 0.8,
        ),
        labelMedium: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w300,
          decorationThickness: 0.8,
        ),
        labelSmall: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w300,
        ),
      ),
      colorScheme: brandColorScheme,
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: const Color(0x122334FF),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xffFF8E00),
        circularTrackColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFFDDEDFC),
      cardTheme: CardTheme(color: brandColorScheme.background, elevation: 0),
      dialogTheme: DialogTheme(
        iconColor: const Color(0xFF67A24A),
        backgroundColor: const Color(0xFF122D46),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(18),
          elevation: 0,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: brandColorScheme.secondary,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.white,
        ),
      ),
      dividerTheme: const DividerThemeData(
        indent: 75,
        endIndent: 15,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF3AE3E0),
          ),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF898989),
          fontWeight: FontWeight.w300,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xff1D293E),
        unselectedLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        selectedLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 18),
        unselectedIconTheme: IconThemeData(color: Colors.white, size: 18),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xff1D293E),
        indicatorColor: Color(0xff1E4E7B),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 18),
        unselectedIconTheme: IconThemeData(color: Colors.white, size: 18),
      ),
    );
  }
}
