import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_icon_picker/utils.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

//Main container for all activity item widgets
class ActivityUserCentricItemContainerWidget extends ConsumerWidget {
  final IconData actionIcon;
  final String actionTitle;
  final Color? actionIconColor;
  final ActivityObject? activityObject;
  final String userId;
  final String roomId;
  final Widget? subtitle;
  final int originServerTs;

  const ActivityUserCentricItemContainerWidget({
    super.key,
    required this.actionIcon,
    required this.actionTitle,
    this.actionIconColor,
    this.activityObject,
    required this.userId,
    required this.roomId,
    this.subtitle,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => onActivityObjectTap(context,ref),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildActionInfoUI(context, ref),
              const SizedBox(height: 6),
              buildUserInfoUI(context, ref),
              TimeAgoWidget(originServerTs: originServerTs),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionInfoUI(BuildContext context, WidgetRef ref) {
    final actionTitleStyle = Theme.of(context).textTheme.labelMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(actionIcon, size: 16, color: actionIconColor),
        const SizedBox(width: 4),
        Text(actionTitle, style: actionTitleStyle),
        if (activityObject != null) ...[
          const SizedBox(width: 6),
          Row(
            children: [
              Icon(getActivityObjectIcon(), size: 16),
              const SizedBox(width: 4),
              Text(getActivityObjectTitle(), style: actionTitleStyle),
            ],
          ),
        ],
        Spacer(),
        ActerIconWidgetFromObjectIdAndType(
          objectId: activityObject?.objectIdStr(),
          objectType: activityObject?.typeStr(),
          fallbackWidget: SizedBox.shrink(),
          iconSize: 24,
        ),
      ],
    );
  }

  Widget buildUserInfoUI(BuildContext context, WidgetRef ref) {
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    return ListTile(
      horizontalTitleGap: 6,
      contentPadding: EdgeInsets.zero,
      leading: ActerAvatar(options: AvatarOptions.DM(memberInfo, size: 32)),
      title: Text(memberInfo.displayName ?? userId),
      subtitle: subtitle ?? const SizedBox.shrink(),
    );
  }

  IconData getActivityObjectIcon() {
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

  void onActivityObjectTap(BuildContext context, WidgetRef ref) {
    if (activityObject == null) {
      debugPrint('Activity object is null');
      return;
    }

    final String? activityType = activityObject?.typeStr();
    final String? objectId = activityObject?.objectIdStr();
    final String? taskListId = activityObject?.taskListIdStr();

    if (activityType == null || objectId == null || objectId.isEmpty) {
      debugPrint('Invalid activity type or object ID');
      return;
    }

    final navigationMap = {
      'pin':
          () => context.pushNamed(
            Routes.pin.name,
            pathParameters: {'pinId': objectId},
          ),
      'task': () {
        if (taskListId != null) {
          context.pushNamed(
            Routes.taskItemDetails.name,
            pathParameters: {'taskId': objectId, 'taskListId': taskListId},
          );
        }
      },
      'task-list':
          () => context.pushNamed(
            Routes.taskListDetails.name,
            pathParameters: {'taskListId': objectId},
          ),
      'event':
          () => context.pushNamed(
            Routes.calendarEvent.name,
            pathParameters: {'calendarId': objectId},
          ),
      'news': () {
        ref.read(updateFilterProvider.notifier).state = UpdateFilters.news;
        context.pushNamed(
          Routes.update.name,
          pathParameters: {'updateId': objectId},
        );
      },
      'story': () {
        ref.read(updateFilterProvider.notifier).state = UpdateFilters.story;
        context.pushNamed(
          Routes.update.name,
          pathParameters: {'updateId': objectId},
        );
      },
    };

    try {
      navigationMap[activityType]?.call() ??
          debugPrint('Tapped on unknown activity: $activityType');
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  String getActivityObjectTitle() {
    return switch (activityObject?.typeStr()) {
      'news' => 'Boost',
      'story' => 'Story',
      _ => activityObject?.title() ?? '',
    };
  }
}
