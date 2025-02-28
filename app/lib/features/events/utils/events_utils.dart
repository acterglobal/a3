import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::cal_event::utils');

Future<void> saveEventTitle({
  required BuildContext context,
  required WidgetRef ref,
  required CalendarEvent calendarEvent,
  required String newName,
}) async {
  final lang = L10n.of(context);
  try {
    EasyLoading.show(status: lang.updateName);
    final updateBuilder = calendarEvent.updateBuilder();
    updateBuilder.title(newName);
    final eventId = await updateBuilder.send();
    _log.info('Calendar Event Title Updated $eventId');
    await autosubscribe(
      ref: ref,
      objectId: calendarEvent.eventId().toString(),
      lang: lang,
    );

    EasyLoading.dismiss();
    if (context.mounted) Navigator.pop(context);
  } catch (e, s) {
    _log.severe('Failed to rename event', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.updateNameFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> saveEventDescription({
  required BuildContext context,
  required WidgetRef ref,
  required CalendarEvent calendarEvent,
  required String htmlBodyDescription,
  required String plainDescription,
}) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.updatingDescription);
  try {
    final updateBuilder = calendarEvent.updateBuilder();
    updateBuilder.descriptionHtml(plainDescription, htmlBodyDescription);
    await updateBuilder.send();
    await autosubscribe(
      ref: ref,
      objectId: calendarEvent.eventId().toString(),
      lang: lang,
    );
    EasyLoading.dismiss();
    if (context.mounted) Navigator.pop(context);
  } catch (e, s) {
    _log.severe('Failed to update event description', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.errorUpdatingDescription(e),
      duration: const Duration(seconds: 3),
    );
  }
}

DateTime calculateDateTimeWithHours(DateTime date, TimeOfDay time) {
  // Replacing hours and minutes from DateTime
  return date.copyWith(hour: time.hour, minute: time.minute);
}

String formatDate(CalendarEvent e) {
  final start = toDartDatetime(e.utcStart()).toLocal();
  final end = toDartDatetime(e.utcEnd()).toLocal();
  final startFmt = DateFormat.yMMMd().format(start);
  if (start.difference(end).inDays == 0) {
    return startFmt;
  } else {
    final endFmt = DateFormat.yMMMd().format(end);
    return '$startFmt - $endFmt';
  }
}

String formatTime(CalendarEvent e) {
  final start = toDartDatetime(e.utcStart()).toLocal();
  final end = toDartDatetime(e.utcEnd()).toLocal();
  return '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}';
}

String getMonthFromDate(UtcDateTime utcDateTime) {
  final localDateTime = toDartDatetime(utcDateTime).toLocal();
  final month = DateFormat.MMM().format(localDateTime);
  return month;
}

String getDayFromDate(UtcDateTime utcDateTime) {
  final localDateTime = toDartDatetime(utcDateTime).toLocal();
  final day = DateFormat.d().format(localDateTime);
  return day;
}

String getTimeFromDate(BuildContext context, UtcDateTime utcDateTime) {
  final localDateTime = toDartDatetime(utcDateTime).toLocal();
  return DateFormat.jm().format(localDateTime);
}

String eventDateFormat(DateTime dateTime) {
  return DateFormat('MMM dd, yyyy').format(dateTime);
}
