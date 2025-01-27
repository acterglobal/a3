import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForTaskItemCompleted(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    final title = "${PushStyles.taskComplete.emoji} $username completed";
    final body = '$parentInfo of $taskList';
    return (title, body);
  } else {
    final title = '${PushStyles.taskComplete.emoji} $username completed Task';
    return (title, null);
  }
}

(String, String?) titleAndBodyForTaskItemReOpened(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    final title = "${PushStyles.taskReOpen.emoji} $username re-opened";
    final body = '$parentInfo of $taskList';
    return (title, body);
  } else {
    final title = '${PushStyles.taskReOpen.emoji} $username re-opened Task';
    return (title, null);
  }
}

(String, String?) titleAndBodyForTaskItemAccepted(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    final title = "${PushStyles.taskAccept.emoji} $username accepted";
    final body = '$parentInfo of $taskList';
    return (title, body);
  } else {
    final title = '${PushStyles.taskAccept.emoji} $username accepted Task';
    return (title, null);
  }
}

(String, String?) titleAndBodyForTaskItemDeclined(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    final title = "${PushStyles.taskDecline.emoji} $username declined";
    final body = '$parentInfo of $taskList';
    return (title, body);
  } else {
    final title = '${PushStyles.taskDecline.emoji} $username declined Task';
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
