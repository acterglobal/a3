import 'dart:async';

import 'package:acter/features/events/providers/notifiers/event_notifiers.dart';
import 'package:acter/features/events/providers/notifiers/rsvp_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mockito/mockito.dart';
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
    return null;
  }
}

class MockEvent extends Fake implements CalendarEvent {
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
