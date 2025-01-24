import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForTaskItemCompleted(
    NotificationItem notification) {
  //Generate comment title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.taskComplete.emoji} $username completed";

  //Generate comment body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    body = '$parentInfo of $taskList';
  } else {
    title = '${PushStyles.taskComplete.emoji} $username completed Task';
  }

  return (title, body);
}

(String, String?) titleAndBodyForTaskItemReOpened(
    NotificationItem notification) {
  //Generate comment title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.taskReOpen.emoji} $username re-opened";

  //Generate comment body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    body = '$parentInfo of $taskList';
  } else {
    title = '${PushStyles.taskReOpen.emoji} $username re-opened Task';
  }

  return (title, body);
}

(String, String?) titleAndBodyForTaskItemAccepted(
    NotificationItem notification) {
  //Generate comment title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.taskAccept.emoji} $username accepted";

  //Generate comment body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    body = '$parentInfo of $taskList';
  } else {
    title = '${PushStyles.taskAccept.emoji} $username accepted Task';
  }

  return (title, body);
}

(String, String?) titleAndBodyForTaskItemDeclined(
    NotificationItem notification) {
  //Generate comment title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.taskDecline.emoji} $username declined";

  //Generate comment body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final taskList = notification.title();
    final parentInfo = parentPart(parent);
    body = '$parentInfo of $taskList';
  } else {
    title = '${PushStyles.taskDecline.emoji} $username declined Task';
  }

  return (title, body);
}

(String, String?) titleAndBodyForTaskItemDueDateChange(
    NotificationItem notification) {

  //Generate attachment body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final taskDueDate = notification.title();

  String? body = 'by $username to "$taskDueDate"';

  //Generate attachment title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = '$parentInfo rescheduled';
  } else {
    title = '$username rescheduled task to "$taskDueDate"';
    body = null;
  }

  return (title, body);
}
