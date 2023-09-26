import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SpaceWithProfileCard extends StatelessWidget {
  final String roomId;
  final ProfileData profile;
  final Widget? subtitle;
  final Widget? trailing;
  final double avatarSize;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  /// Called when the user long-presses on this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback? onLongPress;

  /// {@macro flutter.material.inkwell.onFocusChange}
  final ValueChanged<bool>? onFocusChange;

  /// The text style for ListTile's [title].
  ///
  /// If this property is null, then [ListTileThemeData.titleTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.bodyLarge]
  /// will be used. Otherwise, If ListTile style is [ListTileStyle.list],
  /// [TextTheme.titleMedium] will be used and if ListTile style is [ListTileStyle.drawer],
  /// [TextTheme.bodyLarge] will be used.
  final TextStyle? titleTextStyle;

  /// The text style for ListTile's [subtitle].
  ///
  /// If this property is null, then [ListTileThemeData.subtitleTextStyle] is used.
  /// If that is also null, [TextTheme.bodyMedium] will be used.
  final TextStyle? subtitleTextStyle;

  /// The text style for ListTile's [leading] and [trailing].
  ///
  /// If this property is null, then [ListTileThemeData.leadingAndTrailingTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.labelSmall]
  /// will be used, otherwise [TextTheme.bodyMedium] will be used.
  final TextStyle? leadingAndTrailingTextStyle;

  /// The tile's internal padding.
  ///
  /// Insets a [ListTile]'s contents: its [leading], [title], [subtitle],
  /// and [trailing] widgets.
  ///
  /// If null, `EdgeInsets.symmetric(horizontal: 16.0)` is used.
  final EdgeInsetsGeometry? contentPadding;

  /// The shape of the card's [Material].
  ///
  /// Defines the card's [Material.shape].
  ///
  /// If this property is null then [CardTheme.shape] of [ThemeData.cardTheme]
  /// is used. If that's null then the shape will be a [RoundedRectangleBorder]
  /// with a circular corner radius of 4.0.
  final ShapeBorder? shape;

  /// Whether or not to render a border around that element.
  ///
  /// Overwritten if you provider a `shape`. Otherwise, if set to true renders
  /// the default border.
  final bool withBorder;

  /// Whether or not to render the parent Icon
  ///
  final bool showParent;

  const SpaceWithProfileCard({
    super.key,
    required this.roomId,
    required this.profile,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.shape,
    this.withBorder = true,
    this.showParent = true,
    required this.avatarSize,
    required this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = profile.displayName;
    final title =
        displayName != null && displayName.isNotEmpty ? displayName : roomId;
    final avatar = ActerAvatar(
      mode: DisplayMode.Space,
      uniqueId: roomId,
      displayName: title,
      avatar: profile.getAvatarImage(),
      size: avatarSize,
    );

    return Card(
      color: const Color(0xFF0A1A29),
      shape: renderShape(context),
      child: ListTile(
        contentPadding: contentPadding,
        onTap: onTap ?? () => context.go('/$roomId'),
        onFocusChange: onFocusChange,
        onLongPress: onLongPress,
        titleTextStyle: titleTextStyle,
        subtitleTextStyle: subtitleTextStyle,
        leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
        title: Text(title),
        subtitle: subtitle,
        leading: showParent
            ? SpaceParentBadge(
                roomId: roomId,
                badgeSize: avatarSize / 2,
                child: avatar,
              )
            : avatar,
        trailing: trailing,
      ),
    );
  }

  ShapeBorder? renderShape(BuildContext context) {
    if (shape != null) {
      return shape;
    }
    if (withBorder) {
      return RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.inversePrimary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      );
    }
    return null;
  }
}
