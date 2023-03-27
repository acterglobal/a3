import 'dart:typed_data';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileData {
  final String displayName;
  final FfiBufferUint8? avatar;
  const ProfileData(this.displayName, this.avatar);

  bool hasAvatar() {
    return avatar != null;
  }

  MemoryImage? getAvatarImage() {
    if (avatar == null) {
      return null;
    }
    return MemoryImage(avatar!.asTypedList());
  }
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
