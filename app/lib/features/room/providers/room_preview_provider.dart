import 'dart:typed_data';

import 'package:acter/common/extensions/record_helpers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';

typedef RoomPreviewQuery = ({
  String roomIdOrAlias,
  AllHashed<String> serverNames
});

final roomPreviewProvider =
    FutureProvider.family<RoomPreview, RoomPreviewQuery>((ref, query) async {
  final sdk = await ref.read(sdkProvider.future);
  VecStringBuilder servers = sdk.api.newVecStringBuilder();
  for (final server in query.serverNames.items) {
    servers.add(server);
  }
  final client = ref.watch(alwaysClientProvider);
  final prev = await client.roomPreview(query.roomIdOrAlias, servers);
  return prev;
});

final _roomPreviewAvatarProvider =
    FutureProvider.family<MemoryImage?, RoomPreviewQuery>((ref, q) async {
  final sdk = await ref.watch(sdkProvider.future);
  final thumbsize = sdk.api.newThumbSize(48, 48);
  final room = await ref.watch(roomPreviewProvider(q).future);
  if (!room.hasAvatar()) return null;
  final avatar = await room.avatar(thumbsize);
  return avatar
      .data()
      .map((data) => MemoryImage(Uint8List.fromList(data.asTypedList())));
});

final roomPreviewAvatarInfo =
    StateProvider.family<AvatarInfo, RoomPreviewQuery>((ref, q) {
  final preview = ref.watch(roomPreviewProvider(q)).valueOrNull;
  final avatarData = ref.watch(_roomPreviewAvatarProvider(q)).valueOrNull;
  return AvatarInfo(
    uniqueId: q.roomIdOrAlias,
    displayName: preview?.name(),
    avatar: avatarData,
  );
});
