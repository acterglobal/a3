import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/avatar_with_action_icon.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/object_icon_widget.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/room_providers.dart';

class ActivityIndividualActionContainerWidget extends ConsumerWidget {
  final ActivityObject? activityObject;
  final String userId;
  final String roomId;
  final String actionTitle;
  final IconData actionIcon;
  final Color? actionIconBgColor;
  final Color? actionIconColor;
  final String target;
  final int originServerTs;

  const ActivityIndividualActionContainerWidget({
    super.key,
    this.activityObject,
    required this.userId,
    required this.roomId,
    required this.actionTitle,
    required this.actionIcon,
    this.actionIconColor,
    this.actionIconBgColor,
    required this.target,
    required this.originServerTs,
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
                _buildDisplayNameAndAction(context, theme, displayName),
                const SizedBox(height: 4),
                _buildSubtitleOrTime(context, displayName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// RichText for displayName, action, and target
  Widget _buildDisplayNameAndAction(
    BuildContext context,
    ThemeData theme,
    String displayName,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            target,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (activityObject != null)
          ObjectIconWidget(objectType: activityObject?.typeStr()),
      ],
    );
  }

  /// Subtitle + time or only time if subtitle is null
  Widget _buildSubtitleOrTime(BuildContext context, String displayName) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: displayName, style: theme.textTheme.labelSmall),
                TextSpan(
                  text: ' $actionTitle ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.surfaceTint,
                  ),
                ),
              ],
            ),
          ),
        ),
        TimeAgoWidget(originServerTs: originServerTs),
      ],
    );
  }
}
