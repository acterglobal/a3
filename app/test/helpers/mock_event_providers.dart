import 'dart:async';

import 'package:acter/features/datetime/providers/notifiers/now_notifier.dart';
import 'package:acter/features/events/providers/notifiers/event_notifiers.dart';
import 'package:acter/features/events/providers/notifiers/rsvp_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockAsyncCalendarEventNotifier
    extends AutoDisposeFamilyAsyncNotifier<CalendarEvent, String>
    with Mock
    implements AsyncCalendarEventNotifier {
  bool shouldFail;

  MockAsyncCalendarEventNotifier({this.shouldFail = true});

  @override
  Future<CalendarEvent> build(String arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail: Space not loaded';
    }
    return MockEvent();
  }
}

class MockAsyncRsvpStatusNotifier
    extends AutoDisposeFamilyAsyncNotifier<RsvpStatusTag?, String>
    with Mock
    implements AsyncRsvpStatusNotifier {
  @override
  Future<RsvpStatusTag?> build(String arg) async {
    return switch (arg) {
      'yes' => RsvpStatusTag.Yes,
      'no' => RsvpStatusTag.No,
      'maybe' => RsvpStatusTag.Maybe,
      _ => null,
    };
  }
}

class MockEvent extends Fake implements CalendarEvent {
  @override
  EventId eventId() => MockEventId();

  @override
  String roomIdStr() => 'testRoomId';

  @override
  String title() => 'Fake Event';

  @override
  TextMessageContent? description() => null;

  @override
  UtcDateTime utcStart() => FakeUtcDateTime();

  @override
  UtcDateTime utcEnd() => FakeUtcDateTime();

  @override
  Future<FfiListFfiString> participants() =>
      Completer<FfiListFfiString>().future;

  @override
  Future<AttachmentsManager> attachments() =>
      Completer<AttachmentsManager>().future;

  @override
  Future<CommentsManager> comments() => Completer<CommentsManager>().future;
}

class FakeUtcDateTime extends Fake implements UtcDateTime {
  @override
  int timestampMillis() => 10;
}

class MockUtcNowNotifier extends Mock implements UtcNowNotifier {}

class MockEventId extends Mock implements EventId {}
