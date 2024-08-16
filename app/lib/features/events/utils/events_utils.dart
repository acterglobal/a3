import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::event::utils');

Future<void> saveEventTitle({
  required BuildContext context,
  required CalendarEvent calendarEvent,
  required String newName,
}) async {
  try {
    EasyLoading.show(status: L10n.of(context).updateName);
    final updateBuilder = calendarEvent.updateBuilder();
    updateBuilder.title(newName);
    final eventId = await updateBuilder.send();
    _log.info('Calendar Event Title Updated $eventId');

    EasyLoading.dismiss();
    if (context.mounted) Navigator.pop(context);
  } catch (e, s) {
    _log.severe('Failed to edit event name', e, s);
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(L10n.of(context).updateNameFailed(e));
  }
}

Future<void> saveEventDescription({
  required BuildContext context,
  required CalendarEvent calendarEvent,
  required String htmlBodyDescription,
  required String plainDescription,
}) async {
  EasyLoading.show(status: L10n.of(context).updatingDescription);
  try {
    final updateBuilder = calendarEvent.updateBuilder();
    updateBuilder.descriptionHtml(plainDescription, htmlBodyDescription);
    await updateBuilder.send();
    EasyLoading.dismiss();
    if (context.mounted) Navigator.pop(context);
  } catch (e, s) {
    _log.severe('Failed to update event description', e, s);
    EasyLoading.dismiss();
    if (!context.mounted) return;
    EasyLoading.showError(
      L10n.of(context).errorUpdatingDescription(e),
      duration: const Duration(seconds: 3),
    );
  }
}

DateTime calculateDateTimeWithHours(DateTime date, TimeOfDay time) {
  // Replacing hours and minutes from DateTime
  return date.copyWith(hour: time.hour, minute: time.minute);
}
