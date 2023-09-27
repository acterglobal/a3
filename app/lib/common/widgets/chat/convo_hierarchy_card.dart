import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_with_profile_card.dart';
import 'package:acter/common/widgets/spaces/space_hierarchy_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConvoHierarchyCard extends ConsumerWidget {
  final SpaceHierarchyRoomInfo space;
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

  const ConvoHierarchyCard({
    super.key,
    required this.space,
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = space.roomIdStr();
    final profile = ref.watch(spaceHierarchyProfileProvider(space));
    final topic = space.topic();
    final Widget? subtitle =
        topic != null && topic.isNotEmpty ? Text(topic) : null;

    return profile.when(
      data: (profile) => ConvoWithProfileCard(
        showParent: false,
        roomId: roomId,
        profile: profile,
        subtitle: subtitle,
        trailing: RoomHierarchyJoinButtons(
          space: space,
          forward: (roomId) => context.pushNamed(
            Routes.chatroom.name,
            pathParameters: {
              'roomId': roomId,
            },
          ),
        ),
        onTap: onTap,
        onFocusChange: onFocusChange,
        onLongPress: onLongPress,
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
