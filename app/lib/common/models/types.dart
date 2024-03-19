import 'dart:io';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

typedef ChatWithProfileData = ({Convo chat, ProfileData profile});
typedef SpaceWithProfileData = ({Space space, ProfileData profile});
typedef MemberInfo = ({String userId, String roomId});
typedef ChatMessageInfo = ({String messageId, String roomId});

typedef MemberWithProfile = ({Member member, ProfileData profile});

enum AttachmentType { camera, image, audio, video, location, file }

typedef AttachmentInfo = ({AttachmentType type, File file});
