import 'dart:io';

typedef MemberInfo = ({String userId, String roomId});
typedef ChatMessageInfo = ({String messageId, String roomId});
typedef RoomQuery = ({String roomId, String query});

enum AttachmentType { camera, image, audio, video, location, file, link }

typedef AttachmentInfo = ({AttachmentType type, File file});

enum UrgencyBadge { urgent, important, unread, read, none }
