import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/local.dart';
import 'package:acter_notifify/matrix.dart';
import 'package:acter_notifify/util.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::notifify::android');

final Map<String, List<Message>> pendingMessage = {};

void androidClearNotificationsCache(String threadId) {
  pendingMessage.remove(threadId);
}

Future<ByteArrayAndroidBitmap?> _fetchImage(
  NotificationItem notification,
) async {
  if (notification.hasImage()) {
    try {
      final image = await notification.image();
      return ByteArrayAndroidBitmap(image.asTypedList());
    } catch (e, s) {
      _log.severe('fetching image data failed', e, s);
      Sentry.captureException(e, stackTrace: s);
    }
  }
  return null;
}

Future<Person> _makeSenderPerson(NotificationItem notification) async {
  final sender = notification.sender();
  if (sender.hasImage()) {
    try {
      final image = await sender.image();
      return Person(
        icon: ByteArrayAndroidIcon(image.asTypedList()),
        key: sender.userId(),
        name: sender.displayName(),
      );
    } catch (e, s) {
      _log.severe('fetching image data failed', e, s);
      Sentry.captureException(e, stackTrace: s);
    }
  }
  return Person(key: sender.userId(), name: sender.displayName());
}

Future<ByteArrayAndroidBitmap?> _fetchRoomAvatar(
  NotificationItem notification,
) async {
  final room = notification.room();
  if (room.hasImage()) {
    try {
      final image = await room.image();
      return ByteArrayAndroidBitmap(image.asTypedList());
    } catch (e, s) {
      _log.severe('fetching room avatar failed', e, s);
      Sentry.captureException(e, stackTrace: s);
    }
  }
  return null;
}

Future<void> _androidShow(
  NotificationItem notification,
  AndroidNotificationDetails androidNotificationDetails, {
  String? body,
  String? title,
  String? payload,
}) async {
  await flutterLocalNotificationsPlugin.show(
    id++,
    title ?? notification.title(),
    body,
    NotificationDetails(android: androidNotificationDetails),
    payload: payload ?? notification.targetUrl(),
  );
}

Future<void> _showInvite(NotificationItem notification) async {
  String? threadId = notification.threadId();
  final roomAvatar = await _fetchRoomAvatar(notification);
  final person = await _makeSenderPerson(notification);
  final title = notification.title();
  await _androidShow(
    notification,
    AndroidNotificationDetails(
      'invites',
      'Invites',
      channelDescription: 'When you are invited to spaces or chats',
      groupKey: threadId,
      autoCancel: true,
      largeIcon: roomAvatar,
      importance: Importance.high,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      styleInformation: MessagingStyleInformation(
        person,
        groupConversation: true,
        conversationTitle: title,
        messages: [
          Message('invited you to join', DateTime.now(), person),
        ],
      ),
    ),
    title: title,
  );
}

Future<void> _showNews(NotificationItem notification) async {
  String? threadId = notification.threadId();
  final roomAvatar = await _fetchRoomAvatar(notification);

  final image = await _fetchImage(notification);
  if (image != null) {
    await _androidShow(
      notification,
      AndroidNotificationDetails(
        'updates',
        'Updates',
        channelDescription: 'Updates from your spaces',
        groupKey: threadId,
        autoCancel: true,
        largeIcon: roomAvatar,
        importance: Importance.high,
        priority: Priority.max,
        category: AndroidNotificationCategory.message,
        styleInformation: BigPictureStyleInformation(image),
      ),
    );
  } else {
    final msg = notification.body();
    if (msg != null) {
      final formatted = msg.formattedBody();
      final body = msg.body();

      await _androidShow(
        notification,
        AndroidNotificationDetails(
          'updates',
          'Updates',
          channelDescription: 'Updates from your spaces',
          groupKey: threadId,
          autoCancel: true,
          largeIcon: roomAvatar,
          importance: Importance.high,
          priority: Priority.max,
          category: AndroidNotificationCategory.message,
          styleInformation: BigTextStyleInformation(
            formatted ?? body,
            htmlFormatBigText: formatted != null,
          ),
        ),
        body: body,
      );
    }
  }
}

Future<void> _showChat(NotificationItem notification) async {
  String? threadId = notification.threadId();
  final roomAvatar = await _fetchRoomAvatar(notification);

  _log.info('notification for chat in $threadId');
  final person = await _makeSenderPerson(notification);
  final msg = notification.body()!;
  final formatted = msg.formattedBody();
  final title = notification.title();
  String? body;
  if (formatted != null) {
    body = formatted;
  } else {
    body = msg.body();
  }
  final message = Message(body, DateTime.now(), person);
  late List<Message> messages;
  if (threadId != null) {
    if (pendingMessage.containsKey(threadId)) {
      pendingMessage[threadId]!.add(message);
      await cancelInThread(threadId); // clear any pending messages
    } else {
      pendingMessage[threadId] = [message];
    }
    messages = pendingMessage[threadId]!;
  } else {
    messages = [message];
  }

  await _androidShow(
    notification,
    AndroidNotificationDetails(
      'chat',
      'Chat',
      channelDescription: 'Chat messages from group conversations',
      groupKey: threadId,
      autoCancel: true,
      setAsGroupSummary: true,
      largeIcon: roomAvatar,
      importance: Importance.high,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      styleInformation: MessagingStyleInformation(
        person,
        groupConversation: true,
        conversationTitle: title,
        messages: messages,
        htmlFormatContent: formatted != null,
      ),
    ),
    body: body,
    title: title,
  );
}

Future<void> _showDM(NotificationItem notification) async {
  _log.info('notification for dm');
  String? threadId = notification.threadId();
  final roomAvatar = await _fetchRoomAvatar(notification);
  final person = await _makeSenderPerson(notification);
  final msg = notification.body()!;
  final formatted = msg.formattedBody();
  final title = msg.body();
  String? body;

  if (formatted != null) {
    body = formatted;
  } else {
    body = msg.body();
  }
  _log.info('$title, $body');

  final message = Message(body, DateTime.now(), person);
  late List<Message> messages;
  if (threadId != null) {
    if (pendingMessage.containsKey(threadId)) {
      pendingMessage[threadId]!.add(message);
      await cancelInThread(threadId); // clear any pending messages
    } else {
      pendingMessage[threadId] = [message];
    }
    messages = pendingMessage[threadId]!;
  } else {
    messages = [message];
  }

  await _androidShow(
    notification,
    AndroidNotificationDetails(
      'dm',
      'DM',
      channelDescription: 'Chat messages from DMs',
      groupKey: threadId,
      autoCancel: true,
      largeIcon: roomAvatar,
      importance: Importance.high,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      styleInformation: MessagingStyleInformation(
        person,
        groupConversation: false,
        messages: messages,
        htmlFormatContent: formatted != null,
      ),
    ),
    body: body,
    title: title,
  );
}

Future<void> _showObjNotif(NotificationItem notification) async {
  final (title, body) = genTitleAndBody(notification);
  await _androidShow(
    notification,
    AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Messages sent to you',
      importance: Importance.high,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      groupKey: notification.threadId(),
    ),
    title: title,
    body: body,
  );
}

Future<void> _showFallback(NotificationItem notification) async {
  await _androidShow(
    notification,
    AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Messages sent to you',
      importance: Importance.high,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      groupKey: notification.threadId(),
    ),
  );
}

Future<void> showNotificationOnAndroid(NotificationItem notification) async {
  String pushStyle = notification.pushStyle();

  await (switch (pushStyle) {
    'invite' => _showInvite(notification),
    'news' => _showNews(notification),
    'chat' => _showChat(notification),
    'dm' => _showDM(notification),
    'unknown' || '' || 'fallback' => _showFallback(notification),
    _ => _showObjNotif(notification),
  });
}
