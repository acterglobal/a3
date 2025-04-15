import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final topicProvider = FutureProvider.family<String?, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  return room?.topic();
});
