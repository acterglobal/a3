import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/space_with_profile_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

typedef SubtitleFn = Widget? Function(Space);

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

  /// Custom Trailing Widget
  final Widget? trailing;

  /// Whether or not to render the parent Icon
  ///
  final bool showParent;

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
    this.showParent = true,
    this.trailing,
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
    this.showParent = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = space.getRoomIdStr();
    final profile = ref.watch(spaceProfileDataProvider(space));
    final subtitle = subtitleFn != null ? subtitleFn!(space) : null;
    final parent = ref.watch(canonicalParentProvider(roomId));

    return profile.when(
      data: (profile) => SpaceWithProfileCard(
        roomId: roomId,
        profile: profile,
        parentProfile: parent.valueOrNull?.profile,
        parentRoomId: parent.valueOrNull?.space.getRoomIdStr(),
        subtitle: subtitle,
        onTap: onTap,
        onFocusChange: onFocusChange,
        onLongPress: onLongPress,
        avatarSize: avatarSize,
        contentPadding: contentPadding,
        shape: shape,
        withBorder: withBorder,
        showParent: showParent,
        trailing: trailing,
      ),
      error: (error, stack) => ListTile(
        title: Text(
          L10n.of(context).errorLoadingRoom(roomId, error),
        ),
        subtitle: Text('$error'),
      ),
      loading: () => Skeletonizer(
        child: ListTile(
          title: Text(roomId),
          subtitle: Text(L10n.of(context).loading),
        ),
      ),
    );
  }
}
