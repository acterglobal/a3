import 'dart:io';

typedef MemberInfo = ({String userId, String roomId});
typedef ChatMessageInfo = ({String messageId, String roomId});

enum AttachmentType { camera, image, audio, video, location, file }

typedef AttachmentInfo = ({AttachmentType type, File file});

enum UrgencyBadge {
  urgent,
  important,
  unread,
  read,
  none,
}
