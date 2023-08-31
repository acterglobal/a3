import 'package:acter/common/notifications/models.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;

NotificationBrief briefForChat(ffi.Notification notification) {
  final convo = notification.convo();
  final message = notification.roomMessage();
  const route = Routes.chatroom;
  if (convo == null || message == null) {
    return const NotificationBrief(
      title: 'unsupported chat message',
      route: route,
    );
  }

  ffi.RoomEventItem? eventItem = message.eventItem();
  if (eventItem == null) {
    return const NotificationBrief(title: 'unknown chat message', route: route);
  }

  // String sender = eventItem.sender();
  String eventType = eventItem.eventType();
  // message event
  switch (eventType) {
    case 'm.call.answer':
    case 'm.call.candidates':
    case 'm.call.hangup':
    case 'm.call.invite':
    case 'm.room.aliases':
    case 'm.room.avatar':
    case 'm.room.canonical_alias':
    case 'm.room.create':
    case 'm.room.encryption':
    case 'm.room.guest.access':
    case 'm.room.history_visibility':
    case 'm.room.join.rules':
    case 'm.room.name':
    case 'm.room.pinned_events':
    case 'm.room.power_levels':
    case 'm.room.server_acl':
    case 'm.room.third_party_invite':
    case 'm.room.tombstone':
    case 'm.room.topic':
    case 'm.space.child':
    case 'm.space.parent':
    case 'm.room.message':
      String? subType = eventItem.subType();
      switch (subType) {
        case 'm.audio':
        case 'm.file':
        case 'm.image':
        case 'm.video':
        case 'm.emote':
        case 'm.location':
        case 'm.key.verification.request':
        case 'm.notice':
        case 'm.server_notice':
        case 'm.text':
          return NotificationBrief.fromTextDesc(eventItem.textDesc(), route);
      }
      return NotificationBrief(title: subType ?? eventType, route: route);

    case 'm.reaction':
    case 'm.sticker':
    case 'm.room.member':
      return NotificationBrief.fromTextDesc(eventItem.textDesc(), route);
    case 'm.room.redaction':
      return const NotificationBrief(title: 'Message deleted', route: route);
    case 'm.room.encrypted':
      return const NotificationBrief(title: 'encrypted message', route: route);
    default:
      return NotificationBrief(title: eventType, route: route);
  }
}

NotificationBrief extractBrief(ffi.Notification notification) {
  if (notification.isActerSpace()) {
    return NotificationBrief.unsupported();
  } else if (notification.isSpace()) {
    return NotificationBrief.unsupported();
  } else {
    return briefForChat(notification);
  }
}
