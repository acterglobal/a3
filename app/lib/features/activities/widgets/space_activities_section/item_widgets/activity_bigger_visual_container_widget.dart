import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final avatarInfo = ref.watch(memberAvatarInfoProvider((roomId: roomId, userId: userId)));
    final displayName = ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ?? userId;

    return Container(
      padding: leadingWidget == null ? const EdgeInsets.symmetric(vertical: 10) : const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingWidget ?? _buildAvatarWithIcon(avatarInfo),
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

  /// Avatar with Action Icon overlay
  Widget _buildAvatarWithIcon(AvatarInfo avatarInfo) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 22)),
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerLow,
            ),
            child: Icon(
              actionIcon,
              color: colorScheme.onSurface,
              size: 15,
            ),
          ),
        ),
      ],
    );
  }

  /// RichText for displayName, action, and target
  Widget _buildRichTextHeader(BuildContext context, ThemeData theme, String displayName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: displayName, style: theme.textTheme.bodyMedium),
                TextSpan(
                  text: ' $actionTitle ',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.surfaceTint),
                ),
                TextSpan(text: target, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        if (activityObject != null)
          Icon(
            _getActivityObjectIcon(),
            size: 16,
            color: colorScheme.surfaceTint,
          ),
      ],
    );
  }

  /// Subtitle + time or only time if subtitle is null
  Widget _buildSubtitleOrTime() {
  if (subtitle != null) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: subtitle ?? const SizedBox.shrink()),
          const SizedBox(width: 8),
          Align(
            alignment: Alignment.bottomCenter,
            child: TimeAgoWidget(originServerTs: originServerTs),
          ),
        ],
      ),
    );
  }
  return TimeAgoWidget(originServerTs: originServerTs);
}


  IconData _getActivityObjectIcon() {
    return switch (activityObject?.typeStr()) {
      'news' => PhosphorIconsRegular.rocketLaunch,
      'story' => PhosphorIconsRegular.book,
      'event' => PhosphorIconsRegular.calendar,
      'pin' => PhosphorIconsRegular.pushPin,
      'task-list' => PhosphorIconsRegular.listChecks,
      'task' => PhosphorIconsRegular.checkCircle,
      _ => PhosphorIconsRegular.question,
    };
  }
}
