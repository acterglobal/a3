import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchItemProfileData = Provider.autoDispose
    .family<AvatarInfo, PublicSearchResultItem>((ref, publicSpace) {
  return ref.watch(roomAvatarInfoProvider(publicSpace.roomIdStr()));
});
