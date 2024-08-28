import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;

Future<List<ffi.CalendarEvent>> sortEventListAscTime(
  List<ffi.CalendarEvent> eventsList,
) async {
  eventsList.sort(
    (a, b) => a.utcStart().timestamp().compareTo(b.utcStart().timestamp()),
  );
  return eventsList;
}

Future<List<ffi.CalendarEvent>> sortEventListDscTime(
  List<ffi.CalendarEvent> eventsList,
) async {
  eventsList.sort(
    (a, b) => b.utcStart().timestamp().compareTo(a.utcStart().timestamp()),
  );
  return eventsList;
}
