import 'dart:async';

import 'package:acter/features/datetime/providers/notifiers/now_notifier.dart';
import 'package:acter/features/events/providers/notifiers/event_notifiers.dart';
import 'package:acter/features/events/providers/notifiers/participants_notifier.dart';
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

class MockFindAsyncCalendarEventNotifier
    extends AutoDisposeFamilyAsyncNotifier<CalendarEvent, String>
    with Mock
    implements AsyncCalendarEventNotifier {
  final List<CalendarEvent> events;

  MockFindAsyncCalendarEventNotifier({required this.events});

  @override
  Future<CalendarEvent> build(String arg) async {
    for (final e in events) {
      if (e.eventId().toString() == arg) {
        return e;
      }
    }
    throw 'Event not found';
  }
}

class MockAsyncParticipantsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<String>, String>
    with Mock
    implements AsyncParticipantsNotifier {
  bool shouldFail;
  List<String> participants;
  MockAsyncParticipantsNotifier({
    this.shouldFail = true,
    this.participants = const [],
  });

  @override
  Future<List<String>> build(String arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail: Space not loaded';
    }
    return participants;
  }
}

class MockAsyncRsvpStatusNotifier
    extends AutoDisposeFamilyAsyncNotifier<RsvpStatusTag?, String>
    with Mock
    implements AsyncRsvpStatusNotifier {
  String? status;

  MockAsyncRsvpStatusNotifier({this.status});

  @override
  Future<RsvpStatusTag?> build(String arg) async {
    return switch (status) {
      'yes' => RsvpStatusTag.Yes,
      'no' => RsvpStatusTag.No,
      'maybe' => RsvpStatusTag.Maybe,
      _ => null,
    };
  }
}

class MockEvent extends Fake implements CalendarEvent {
  final String fakeEventTitle;
  final String fakeEventId;
  final int? fakeEventTs;

  MockEvent({
    this.fakeEventId = 'eventId',
    this.fakeEventTitle = 'Fake Event',
    this.fakeEventTs,
  });

  @override
  EventId eventId() => MockEventId(fakeEventId);

  @override
  String roomIdStr() => 'testRoomId';

  @override
  String title() => fakeEventTitle;

  @override
  TextMessageContent? description() => null;

  @override
  UtcDateTime utcStart() => FakeUtcDateTime(ts: fakeEventTs ?? 10);

  @override
  UtcDateTime utcEnd() => FakeUtcDateTime(ts: (fakeEventTs ?? 10) + 10);

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
  final int ts;
  FakeUtcDateTime({this.ts = 10});
  @override
  int timestampMillis() => ts;

  @override
  int timestamp() => ts;
}

class MockUtcNowNotifier extends StateNotifier<DateTime>
    implements UtcNowNotifier {
  MockUtcNowNotifier({DateTime? state, int? ts})
    : super(
        state ??
            (ts != null
                    ? DateTime.fromMillisecondsSinceEpoch(ts)
                    : DateTime.now())
                .toUtc(),
      );
}

class MockEventId extends Mock implements EventId {
  final String fakeEventId;

  MockEventId(this.fakeEventId);

  @override
  String toString() => fakeEventId;
}

class MockEventListSearchFilterProvider extends Mock {}
