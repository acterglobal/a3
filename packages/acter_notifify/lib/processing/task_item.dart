import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForTaskItemCompleted(
    NotificationItem notification) {
  final emoji = PushStyles.taskComplete.emoji;

  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    final title = getUserCentricTitlePart(notification, emoji, 'completed');
    final body = '$parentInfo of $taskList';
    return (title, body);
  } else {
    final title =
        getUserCentricTitlePart(notification, emoji, 'completed Task');
    return (title, null);
  }
}

(String, String?) titleAndBodyForTaskItemReOpened(
    NotificationItem notification) {
  final emoji = PushStyles.taskReOpen.emoji;

  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    final title = getUserCentricTitlePart(notification, emoji, 're-opened');
    final body = '$parentInfo of $taskList';
    return (title, body);
  } else {
    final title =
        getUserCentricTitlePart(notification, emoji, 're-opened Task');
    return (title, null);
  }
}

(String, String?) titleAndBodyForTaskItemAccepted(
    NotificationItem notification) {
  final emoji = PushStyles.taskAccept.emoji;

  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    final title = getUserCentricTitlePart(notification, emoji, 'accepted');
    final body = '$parentInfo of $taskList';
    return (title, body);
  } else {
    final title = getUserCentricTitlePart(notification, emoji, 'accepted Task');
    return (title, null);
  }
}

(String, String?) titleAndBodyForTaskItemDeclined(
    NotificationItem notification) {
  final emoji = PushStyles.taskDecline.emoji;

  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    final title = getUserCentricTitlePart(notification, emoji, 'declined');
    final body = '$parentInfo of $taskList';
    return (title, body);
  } else {
    final title = getUserCentricTitlePart(notification, emoji, 'declined Task');
    return (title, null);
  }
}

(String, String?) titleAndBodyForTaskItemDueDateChange(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final taskDueDate = notification.title();

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    final title = '$parentInfo rescheduled';
    final body = 'by $username to "$taskDueDate"';
    return (title, body);
  } else {
    final title = '$username rescheduled task to "$taskDueDate"';
    return (title, null);
  }
}
