import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ProfileData {
  final String? displayName;
  final FfiBufferUint8? avatar;
  final bool isDm;
  MemoryImage? avatarMem;

  ProfileData(this.displayName, this.avatar, {this.isDm = false});

  bool hasAvatar() {
    return avatar != null;
  }

  MemoryImage? getAvatarImage() {
    if (avatarMem == null) {
      if (avatar == null) {
        return null;
      }
      avatarMem = MemoryImage(avatar!.asTypedList());
    }
    return avatarMem;
  }
}
