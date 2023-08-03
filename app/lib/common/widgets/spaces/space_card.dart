import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

typedef Widget? SubtitleFn(Space);

class SpaceCard extends ConsumerWidget {
  final Space space;
  final SubtitleFn? subtitleFn;
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

  const SpaceCard({
    super.key,
    required this.space,
    this.subtitleFn,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.avatarSize = 48,
    this.contentPadding = const EdgeInsets.all(15),
    this.shape,
    this.withBorder = true,
  });

  const SpaceCard.small({
    super.key,
    required this.space,
    this.subtitleFn,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.avatarSize = 24,
    this.contentPadding = const EdgeInsets.all(5),
    this.shape,
    this.withBorder = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = space.getRoomId().toString();
    final profile = ref.watch(spaceProfileDataProvider(space));
    final subtitle = subtitleFn != null ? subtitleFn!(space) : null;

    ShapeBorder? renderShape() {
      return shape ??
          (withBorder
              ? RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                )
              : null);
    }

    return profile.when(
      data: (profile) => SpaceWithProfileCard(
        space: space,
        profile: profile,
        subtitle: subtitle,
        onTap: onTap,
        onFocusChange: onFocusChange,
        onLongPress: onLongPress,
        avatarSize: avatarSize,
        contentPadding: contentPadding,
        shape: renderShape(),
      ),
      error: (error, stack) => ListTile(
        title: Text('Error loading: $roomId'),
        subtitle: Text('$error'),
      ),
      loading: () => ListTile(
        title: Text(roomId),
        subtitle: const Text('loading'),
      ),
    );
  }
}

class SpaceWithProfileCard extends ConsumerWidget {
  final Space space;
  final ProfileData profile;
  final Widget? subtitle;
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

  const SpaceWithProfileCard({
    super.key,
    required this.space,
    required this.profile,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.shape,
    required this.avatarSize,
    required this.contentPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = space.getRoomId().toString();
    final displayName = profile.displayName ?? roomId;
    return Card(
      shape: shape,
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        contentPadding: contentPadding,
        onTap: onTap ?? () => context.go('/$roomId'),
        onFocusChange: onFocusChange,
        onLongPress: onLongPress,
        titleTextStyle: titleTextStyle,
        subtitleTextStyle: subtitleTextStyle,
        leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
        title: Text(profile.displayName ?? roomId),
        subtitle: subtitle,
        leading: profile.hasAvatar()
            ? ActerAvatar(
                mode: DisplayMode.Space,
                uniqueId: roomId,
                displayName: displayName,
                avatar: profile.getAvatarImage(),
                size: avatarSize,
              )
            : ActerAvatar(
                mode: DisplayMode.Space,
                uniqueId: roomId,
                displayName: displayName,
                size: avatarSize,
              ),
      ),
    );
  }
}
