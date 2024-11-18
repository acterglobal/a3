import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RoomPreviewQuery = ({String roomIdOrAlias, List<String> serverNames});

final roomPreviewProvider = FutureProvider.family
    .autoDispose<RoomPreview, RoomPreviewQuery>((ref, query) async {
  final sdk = await ref.read(sdkProvider.future);
  VecStringBuilder servers = sdk.api.newVecStringBuilder();
  for (final server in query.serverNames) {
    servers.add(server);
  }
  final client = ref.watch(alwaysClientProvider);
  return client.roomPreview(query.roomIdOrAlias, servers);
});

typedef RoomOrPreview = ({Room? room, RoomPreview? preview});

final roomOrPreviewProvider = FutureProvider.family
    .autoDispose<RoomOrPreview, RoomPreviewQuery>((ref, arg) async {
  final room = await ref.watch(maybeRoomProvider(arg.roomIdOrAlias).future);
  if (room != null) {
    return (room: room, preview: null);
  }

  final preview = await ref.watch(roomPreviewProvider(arg).future);
  return (room: null, preview: preview);
});
