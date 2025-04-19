import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lastMessageDisplayNameProvider = Provider.family<String, MemberInfo>((
  ref,
  memberInfo,
) {
  final name = ref.watch(
    memberDisplayNameProvider((
      roomId: memberInfo.roomId,
      userId: memberInfo.userId,
    )),
  );
  final displayName =
      name.valueOrNull ??
      simplifyUserId(memberInfo.userId) ??
      memberInfo.userId;
  return displayName;
});

final lastMessageTextProvider = Provider.family<String?, TimelineEventItem?>((
  ref,
  eventItem,
) {
  final msgContent = eventItem?.message();
  if (msgContent == null) return null;
  return msgContent.body();
});
