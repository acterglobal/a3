import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/avatar_with_action_icon.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/object_icon_widget.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/room_providers.dart';

class ActivityBiggerVisualContainerWidget extends ConsumerWidget {
  final ActivityObject? activityObject;
  final String userId;
  final String roomId;
  final String actionTitle;
  final IconData actionIcon;
  final Widget? leadingWidget;
  final String target;
  final Widget? subtitle;
  final int originServerTs;
  final Color? actionIconBgColor;
  final Color? actionIconColor;

  const ActivityBiggerVisualContainerWidget({
    super.key,
    this.activityObject,
    required this.userId,
    required this.roomId,
    required this.actionTitle,
    required this.actionIcon,
    this.leadingWidget,
    required this.target,
    this.subtitle,
    required this.originServerTs,
    this.actionIconBgColor,
    this.actionIconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    final displayName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        userId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingWidget ??
              AvatarWithActionIcon(
                avatarInfo: avatarInfo,
                actionIcon: actionIcon,
                actionIconBgColor: actionIconBgColor,
                actionIconColor: actionIconColor,
              ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRichTextHeader(context, theme, displayName),
                const SizedBox(height: 4),
                _buildSubtitleOrTime(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// RichText for displayName, action, and target
  Widget _buildRichTextHeader(
    BuildContext context,
    ThemeData theme,
    String displayName,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: displayName, style: theme.textTheme.bodySmall),
                TextSpan(
                  text: ' $actionTitle ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.surfaceTint,
                  ),
                ),
                TextSpan(text: target, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        if (activityObject != null)
          ObjectIconWidget(objectType: activityObject?.typeStr()),
      ],
    );
  }

  /// Subtitle + time or only time if subtitle is null
  Widget _buildSubtitleOrTime() {
    Widget? timeWidget = TimeAgoWidget(originServerTs: originServerTs);
    if (subtitle == null) {
      return Align(alignment: Alignment.bottomRight, child: timeWidget);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: subtitle ?? const SizedBox.shrink()),
          const SizedBox(width: 8),
          Align(alignment: Alignment.bottomRight, child: timeWidget),
        ],
      ),
    );
  }
}
