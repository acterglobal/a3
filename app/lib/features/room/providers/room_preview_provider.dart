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
