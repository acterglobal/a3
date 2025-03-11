import 'dart:typed_data';

import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchItemProfileData = FutureProvider.autoDispose
    .family<AvatarInfo, PublicSearchResultItem>((ref, publicSpace) async {
      final sdk = await ref.read(sdkProvider.future);
      final size = sdk.api.newThumbSize(48, 48);
      final avatar = (await publicSpace.getAvatar(size)).data();
      return AvatarInfo(
        uniqueId: publicSpace.roomIdStr(),
        displayName: publicSpace.name(),
        avatar:
            avatar != null
                ? MemoryImage(Uint8List.fromList(avatar.asTypedList()))
                : null,
      );
    });
