import 'dart:typed_data';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class ProfileData {
  final String displayName;
  final Uint8List? avatar;
  const ProfileData(this.displayName, this.avatar);
}

class ChatWithProfileData {
  final Conversation chat;
  final ProfileData profile;
  const ChatWithProfileData(this.chat, this.profile);
}

class SpaceWithProfileData {
  final Space space;
  final ProfileData profile;
  const SpaceWithProfileData(this.space, this.profile);
}
