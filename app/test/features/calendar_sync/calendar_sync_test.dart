import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/features/calendar_sync/providers/events_to_sync_provider.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_a3sdk.dart';

import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_client_provider.dart';
import '../../helpers/mock_event_providers.dart';
import '../../helpers/mock_room_providers.dart';

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

      final events = generateMockCalendarEvents(count: 10);
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
        List.generate(10, (idx) => 'null-event-$idx-id=resultKey-$idx'),
      );
    });
  });
  group('Calendar Event Updater tests', () {
    testWidgets('basics update fine', (tester) async {
      final events = generateMockCalendarEvents(count: 10);

      final event = Event('1');
      for (final mock in events) {
        await updateEventDetails(mock, null, event);
        // ensuring the general stuff worked
        expect(event.title, mock.title());
        expect(event.description, mock.description()?.body());
        // todo: check the start and end time ...?!?
      }
    });
    testWidgets('status and reminders are set correctly', (tester) async {
      final mockEvent = generateMockCalendarEvents(count: 1).first;
      final targetEvent = Event('1');

      // yes add reminder
      await updateEventDetails(mockEvent, RsvpStatusTag.Yes, targetEvent);
      expect(targetEvent.status, EventStatus.Confirmed);
      expect(targetEvent.reminders?.length, 1);
      expect(targetEvent.reminders?.first.minutes, 10);

      // maybe remove timer
      await updateEventDetails(mockEvent, RsvpStatusTag.No, targetEvent);
      expect(targetEvent.status, EventStatus.Canceled);
      expect(targetEvent.reminders, null);

      targetEvent.reminders = [Reminder(minutes: 30)];
      // not responded removes timer
      await updateEventDetails(mockEvent, null, targetEvent);
      expect(targetEvent.status, EventStatus.None);
      expect(targetEvent.reminders, null);

      targetEvent.reminders = [Reminder(minutes: 30)];
      // maybe adds timer
      await updateEventDetails(mockEvent, RsvpStatusTag.Maybe, targetEvent);
      expect(targetEvent.status, EventStatus.Tentative);
      expect(targetEvent.reminders?.length, 1);
      expect(targetEvent.reminders?.first.minutes, 10);
    });
  });

  group('Calendar Sync Provider test', () {
    testWidgets('by default sync all', (tester) async {
      SharedPreferences.setMockInitialValues({}); // no values set yet.

      final roomAEvents = generateMockCalendarEvents(count: 5, roomId: 'roomA');
      final roomBEvents = generateMockCalendarEvents(count: 5, roomId: 'roomB');
      final roomCEvents = generateMockCalendarEvents(count: 5, roomId: 'roomC');
      final List<MockCalendarEvent> events = [];
      final client = MockClient();
      final mockRoom = MockRoom();
      final Stream<bool> updateSteam = Stream.empty();
      when(() => client.subscribeModelObjectsStream(any(), any()))
          .thenAnswer((a) => updateSteam);
      when(() => mockRoom.userSettings())
          .thenAnswer((_) async => MockRoomUserSettings());
      events.addAll(roomAEvents);
      events.addAll(roomBEvents);
      events.addAll(roomCEvents);

      final container = ProviderContainer(
        overrides: [
          utcNowProvider.overrideWith((ref) => MockUtcNowNotifier()),
          allEventListProvider.overrideWith((r, a) => events),
          clientProvider.overrideWith(() => MockClientNotifier(client: client)),
          maybeRoomProvider.overrideWith(
            () => MockAlwaysTheSameRoomNotifier(
              room: mockRoom,
            ),
          ),
          calendarEventProvider.overrideWith(
            () => MockFindAsyncCalendarEventNotifier(events: events),
          ),
        ],
      );
      addTearDown(container.dispose);

      // keeping the provider alive for the tests
      // ignore: unused_local_variable
      final subscription = container.listen(eventsToSyncProvider, (a, b) {});

      final state = await container.read(eventsToSyncProvider.future);
      expect(
        state.length,
        events.length,
      );
    });
    testWidgets('excluded rooms are excluded', (tester) async {
      SharedPreferences.setMockInitialValues({}); // no values set yet.

      final roomAEvents = generateMockCalendarEvents(count: 5, roomId: 'roomA');
      final roomBEvents = generateMockCalendarEvents(count: 5, roomId: 'roomB');
      final roomCEvents = generateMockCalendarEvents(count: 5, roomId: 'roomC');
      final List<MockCalendarEvent> events = [];
      final roomA = MockRoom();
      final roomB = MockRoom();
      final roomC = MockRoom();
      when(() => roomA.userSettings())
          .thenAnswer((_) async => MockRoomUserSettings());
      when(() => roomB.userSettings()).thenAnswer(
        // b will be ignored
        (_) async => MockRoomUserSettings(include_cal_sync: false),
      );
      when(() => roomC.userSettings())
          .thenAnswer((_) async => MockRoomUserSettings());
      final client = MockClient();
      final Stream<bool> updateSteam = Stream.empty();
      when(() => client.subscribeModelObjectsStream(any(), any()))
          .thenAnswer((a) => updateSteam);
      events.addAll(roomAEvents);
      events.addAll(roomBEvents);
      events.addAll(roomCEvents);
      final container = ProviderContainer(
        overrides: [
          utcNowProvider.overrideWith((ref) => MockUtcNowNotifier()),
          allEventListProvider.overrideWith((r, a) => events),
          clientProvider.overrideWith(() => MockClientNotifier(client: client)),
          maybeRoomProvider.overrideWith(
            () => MockAsyncMaybeRoomNotifier(
              items: {'roomA': roomA, 'roomB': roomB, 'roomC': roomC},
            ),
          ),
          calendarEventProvider.overrideWith(
            () => MockFindAsyncCalendarEventNotifier(events: events),
          ),
        ],
      );
      addTearDown(container.dispose);

      // keeping the provider alive for the tests
      // ignore: unused_local_variable
      final subscription = container.listen(eventsToSyncProvider, (a, b) {});

      final state = await container.read(eventsToSyncProvider.future);
      expect(
        state.length,
        10,
      );
      expect(
        state.map((e) => e.event.roomIdStr()).toSet(),
        {'roomA', 'roomC'},
      );
    });
  });
}
