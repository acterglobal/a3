// report pin dialog
import 'package:acter/common/actions/report_content.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void showReportDialog(BuildContext context, ActerPin pin) {
  final lang = L10n.of(context);
  openReportContentDialog(
    context,
    title: lang.reportThisPin,
    description: lang.reportThisContent,
    eventId: pin.eventIdStr(),
    roomId: pin.roomIdStr(),
    senderId: pin.sender().toString(),
    isSpace: true,
  );
}
