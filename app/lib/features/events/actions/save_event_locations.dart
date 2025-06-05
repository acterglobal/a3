import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::cal_event::actions::save_locations');

Future<void> saveEventLocations({
  required BuildContext context,
  required WidgetRef ref,
  required List<EventLocationDraft> locations,
  required String calendarId,
}) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.updatingLocations);
  try {
    final calendarEvent = ref.read(calendarEventProvider(calendarId)).valueOrNull;
    if (calendarEvent == null) {
      EasyLoading.dismiss();
      return;
    }
  
    final updateBuilder = calendarEvent.updateBuilder();
    updateBuilder.unsetLocations();
    await updateBuilder.send();
    
    await autosubscribe(
      ref: ref,
      objectId: calendarEvent.eventId().toString(),
      lang: lang,
    );

    EasyLoading.dismiss();
    if (context.mounted) Navigator.pop(context);
  } catch (e, s) {
    _log.severe('Failed to update event locations', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.errorUpdatingEvent(e),
      duration: const Duration(seconds: 3),
    );
  }
} 