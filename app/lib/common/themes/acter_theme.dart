import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/themes/components/bottom_sheet_theme.dart';
import 'package:acter/common/themes/components/button_theme.dart';
import 'package:acter/common/themes/components/card_theme.dart';
import 'package:acter/common/themes/components/dialog_theme.dart';
import 'package:acter/common/themes/components/divider_theme.dart';
import 'package:acter/common/themes/components/input_decoration_theme.dart';
import 'package:acter/common/themes/components/list_tile_Theme.dart';
import 'package:acter/common/themes/components/navigationbar_theme.dart';
import 'package:acter/common/themes/components/progress_indicator_theme.dart';
import 'package:acter/common/themes/components/text_theme.dart';
import 'package:flutter/material.dart';

extension ActerChatThemeExtension on ThemeData {
  ActerChatTheme get chatTheme => const ActerChatTheme();

  ElevatedButtonThemeData get dangerButtonTheme =>
      dangerButtonThemeMaker(colorScheme, textTheme);

  TextButtonThemeData get inlineTextButtonTheme =>
      inlineTextButtonThemeMaker(colorScheme);
}

class ActerTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    primaryColor: brandColor,
    indicatorColor: brandColor,
    appBarTheme: AppBarTheme(
      color: backgroundColor,
      surfaceTintColor: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    unselectedWidgetColor: greyColor,
    progressIndicatorTheme: progressIndicatorTheme,
    tabBarTheme: const TabBarTheme(
      indicatorColor: Colors.white,
      labelColor: Colors.white,
    ),
    textTheme: textTheme,
    iconTheme: const IconThemeData(color: Colors.white),
    cardTheme: cardTheme,
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(surfaceColor),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      selectedColor: brandColor,
    ),
    listTileTheme: listTileTheme,
    dialogBackgroundColor: surfaceColor,
    dividerTheme: dividerTheme,
    dialogTheme: dialogTheme,
    bottomSheetTheme: bottomSheetTheme,
    elevatedButtonTheme: elevatedButtonTheme(colorScheme, textTheme),
    outlinedButtonTheme: outlinedButtonTheme(colorScheme, textTheme),
    textButtonTheme: textButtonTheme(colorScheme),
    iconButtonTheme: iconButtonTheme,
    inputDecorationTheme: inputDecorationTheme,
    bottomNavigationBarTheme: bottomNavigationBarTheme,
    navigationRailTheme: navigationRailTheme,
  );
}
