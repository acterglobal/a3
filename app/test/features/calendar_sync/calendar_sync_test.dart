import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_a3sdk.dart';

import 'package:mocktail/mocktail.dart';

class MockDeviceCalendarPlugin extends Mock implements DeviceCalendarPlugin {}

void main() {
  group('Calendar Sync test', () {
    late DeviceCalendarPlugin deviceCalendarFallback;
    setUpAll(() {
      deviceCalendarFallback = deviceCalendar;
      deviceCalendar = MockDeviceCalendarPlugin();
    });

    tearDownAll(() {
      deviceCalendar = deviceCalendarFallback;
    });

    testWidgets('ensure refresh synchronicity', (tester) async {
      SharedPreferences.setMockInitialValues({}); // no values set yet.

      const calendarId = '1';

      final events = generateMockCalendarEvents(10);
      final firstTry =
          events.map((e) => (event: e, rsvp: RsvpStatusTag.Maybe)).toList();
      final secondTry =
          events.map((e) => (event: e, rsvp: RsvpStatusTag.No)).toList();
      final thirdTry =
          events.map((e) => (event: e, rsvp: RsvpStatusTag.Yes)).toList();

      int updateCountId = 0;
      // we start fresh
      when(() => deviceCalendar.createOrUpdateEvent(any()))
          .thenAnswer((a) async {
        final r = Result<String>();
        r.data = 'resultKey-$updateCountId';
        updateCountId += 1;
        return r;
      });

      // create in fast succession;
      final waiter = Future.wait([
        scheduleRefresh(calendarId, firstTry),
        scheduleRefresh(calendarId, secondTry),
        scheduleRefresh(calendarId, thirdTry),
      ]);

      // advance the timer
      await tester.pump(const Duration(seconds: 2));
      // verify nothing happened yet.
      verifyNever(() => deviceCalendar.createOrUpdateEvent(any()));
      // advance the timer again
      await tester.pump(const Duration(seconds: 2));
      // await
      await waiter;

      // ensure this was only called created them once
      verify(() => deviceCalendar.createOrUpdateEvent(any())).called(10);
      // let's read and ensure the mapping:
      final mappedKeys =
          (await sharedPrefs()).getStringList(calendarSyncIdsKey);
      expect(
        mappedKeys,
        List.generate(10, (idx) => 'event-$idx-id=resultKey-$idx'),
      );
    });
  });
}
