import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/avatar_with_action_icon.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivitySpaceCoreActionsContainerWidget extends ConsumerWidget {
  final ActivityObject? activityObject;
  final VoidCallback? onTap;
  final String userId;
  final String roomId;
  final String actionTitle;
  final String target;
  final int originServerTs;

  const ActivitySpaceCoreActionsContainerWidget({
    super.key,
    this.activityObject,
    this.onTap,
    required this.userId,
    required this.roomId,
    required this.actionTitle,
    required this.target,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    final displayName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        userId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarWithActionIcon(
            avatarInfo: avatarInfo,
            actionIcon: PhosphorIconsRegular.pencilSimpleLine,
          ),
          const SizedBox(width: 10),
          _buildTitleOrTime(context, displayName),
        ],
      ),
      ),
    );
  }

  /// Subtitle + time or only time if subtitle is null
  Widget _buildTitleOrTime(BuildContext context, String displayName) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
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
                ],
              ),
            ),
          ),
          TimeAgoWidget(originServerTs: originServerTs),
        ],
      ),
    );
  }
}
