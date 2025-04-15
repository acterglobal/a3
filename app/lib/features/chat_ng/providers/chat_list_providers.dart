import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lastMessageSenderNameProvider =
    Provider.family<String?, TimelineEventItem?>((ref, eventItem) {
      final sender = eventItem?.sender();
      if (sender == null) return null;
      final senderName = simplifyUserId(sender);
      if (senderName == null || senderName.isEmpty) return null;
      return senderName[0].toUpperCase() + senderName.substring(1);
    });

final lastMessageTextProvider = Provider.family<String?, TimelineEventItem?>((
  ref,
  eventItem,
) {
  final msgContent = eventItem?.msgContent();
  if (msgContent == null) return null;
  return msgContent.body();
});
