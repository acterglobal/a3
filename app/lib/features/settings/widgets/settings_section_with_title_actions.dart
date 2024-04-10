import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsSectionWithTitleActions extends AbstractSettingsSection {
  /// The actual title widget
  final Widget title;
  final List<Widget> actions;
  final List<AbstractSettingsTile> tiles;

  const SettingsSectionWithTitleActions({
    super.key,
    required this.title,
    required this.actions,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final tileList = buildTileList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _platformPaddingTitle(context),
            const Spacer(),
            ...actions,
          ],
        ),
        Container(
          color: theme.themeData.settingsSectionBackground,
          child: tileList,
        ),
      ],
    );
  }

  Widget buildTileList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: tiles.length,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return tiles[index];
      },
    );
  }

  Padding _platformPaddingTitle(BuildContext context) {
    final theme = SettingsTheme.of(context);
    final scaleFactor = MediaQuery.of(context).textScaler;

    switch (theme.platform) {
      case DevicePlatform.android:
      case DevicePlatform.fuchsia:
      case DevicePlatform.linux:
        return Padding(
          padding: EdgeInsetsDirectional.only(
            top: scaleFactor.scale(24),
            bottom: scaleFactor.scale(10),
            start: 24,
            end: 24,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: theme.themeData.titleTextColor,
            ),
            child: title,
          ),
        );
      case DevicePlatform.iOS:
      case DevicePlatform.macOS:
      case DevicePlatform.windows:
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: 18,
            bottom: scaleFactor.scale(5),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: theme.themeData.titleTextColor,
              fontSize: 13,
            ),
            child: title,
          ),
        );

      case DevicePlatform.web:
      case DevicePlatform.device:
        throw Exception(
          L10n.of(context).devicePlatformException,
        );
    }
  }
}
