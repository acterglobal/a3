import 'package:acter/router/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('ActivityItemClickAction');

void onTapActivityItem(BuildContext context, ActivityObject? activityObject) {
  final String activityType = activityObject?.typeStr() ?? '';
  final String objectId = activityObject?.objectIdStr() ?? '';
  final String taskListId = activityObject?.taskListIdStr() ?? '';

  if (activityType.isEmpty || objectId.isEmpty) {
    _log.info('onTapActivityItem : activityType or objectId is null');
    return;
  }

  final activityActions = {
    'pin': () => context.pushNamed(
          Routes.pin.name,
          pathParameters: {'pinId': objectId},
        ),
    'task': () => context.pushNamed(
          Routes.taskItemDetails.name,
          pathParameters: {'taskId': objectId, 'taskListId': taskListId},
        ),
    'task-list': () => context.pushNamed(
          Routes.taskListDetails.name,
          pathParameters: {'taskListId': objectId},
        ),
    'event': () => context.pushNamed(
          Routes.calendarEvent.name,
          pathParameters: {'calendarId': objectId},
        ),
    'news': () => context.pushNamed(
          Routes.update.name,
          pathParameters: {'updateId': objectId},
        ),
    'story': () => context.pushNamed(
          Routes.update.name,
          pathParameters: {'updateId': objectId},
        ),
  };

  final action = activityActions[activityType];
  if (action != null) {
    action();
  } else {
    _log.warning('Unknown activity type: $activityType');
  }
}