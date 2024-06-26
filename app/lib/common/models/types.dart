import 'dart:io';

import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

typedef ChatWithAvatarInfo = ({Convo chat, AvatarInfo avatarInfo});
typedef SpaceWithAvatarInfo = ({Space space, AvatarInfo avatarInfo});
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
