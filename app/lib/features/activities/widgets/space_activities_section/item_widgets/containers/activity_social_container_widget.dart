import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/room_providers.dart';

class ActivitySocialContainerWidget extends ConsumerWidget {
  final ActivityObject? activityObject;
  final IconData icon;
  final Color? iconColor;
  final String userId;
  final String roomId;
  final String actionTitle;
  final int originServerTs;

  const ActivitySocialContainerWidget({
    super.key,
    this.activityObject,
    required this.icon,
    this.iconColor,
    required this.userId,
    required this.roomId,
    required this.actionTitle,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        userId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIcon(context),
          const SizedBox(width: 8),
          _buildTitleOrTime(context, displayName),
        ],
      ),
    );
  }

  /// Avatar with Action Icon overlay
  Widget _buildIcon(BuildContext context) {
    return Icon(icon, color: iconColor ?? colorScheme.surfaceTint, size: 16);
  }

  /// Subtitle + time or only time if subtitle is null
  Widget _buildTitleOrTime(BuildContext context, String displayName) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: displayName,
                    style: theme.textTheme.labelSmall,
                  ),
                  TextSpan(
                    text: ' $actionTitle ${getActivityObjectTitle(context)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.surfaceTint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          TimeAgoWidget(originServerTs: originServerTs),
        ],
      ),
    );
  }

  String getActivityObjectTitle(BuildContext context) {
    return switch (activityObject?.typeStr()) {
      'news' => L10n.of(context).boost,
      'story' => L10n.of(context).story,
      _ => activityObject?.title() ?? '',
    };
  }
}
