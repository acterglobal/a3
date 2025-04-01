import 'package:acter/common/actions/report_content.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

Future<void> reportMessageAction(
  BuildContext context,
  TimelineEventItem item,
  String messageId,
  String roomId,
) async {
  final lang = L10n.of(context);
  final senderId = item.sender();
  // pop message action options
  Navigator.pop(context);
  await openReportContentDialog(
    context,
    title: lang.reportThisMessage,
    description: lang.reportMessageContent,
    senderId: senderId,
    roomId: roomId,
    eventId: messageId,
  );
}
