// redact pin dialog
import 'package:acter/common/actions/redact_content.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

void showRedactDialog({
  required BuildContext context,
  required ActerPin pin,
  required String roomId,
}) {
  openRedactContentDialog(
    context,
    title: L10n.of(context).removeThisPin,
    eventId: pin.eventIdStr(),
    onSuccess: () {
      Navigator.pop(context);
    },
    roomId: roomId,
    isSpace: true,
  );
}
