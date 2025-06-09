import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::cal_event::actions::save_locations');

Future<void> loadExistingLocations(WidgetRef ref, String eventId) async {
  final asyncLocations = ref.read(asyncEventLocationsProvider(eventId)).valueOrNull;
  if (asyncLocations != null) {
    final locations = asyncLocations.map((location) => EventLocationDraft(
      name: location.name() ?? '',
      type: location.locationType().toLowerCase() == LocationType.virtual.name 
          ? LocationType.virtual 
          : LocationType.physical,
      url: location.uri(),
      address: location.address(),
      note: location.notes(),
    )).toList();
    ref.read(eventDraftLocationsProvider.notifier).clearLocations();
    for (final location in locations) {
      ref.read(eventDraftLocationsProvider.notifier).addLocation(location);
    }
  }
}

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

    for (final location in locations) {
      if (location.type == LocationType.physical) {
        updateBuilder.addPhysicalLocation(location.name, '', '', '', '',location.address,location.note);
      }
      if (location.type == LocationType.virtual) {
        updateBuilder.addVirtualLocation(location.name, '', '',location.url ?? '',location.note);
      }
    }
    
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