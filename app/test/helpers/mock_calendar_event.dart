// Mock classes
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'mock_event_location.dart';
import 'mock_a3sdk.dart' as a3sdk;

class MockCalendarEvent extends Mock implements CalendarEvent {
  final RsvpStatus? rsvpStatus;
  final String? _title;
  final String? _eventId;
  final String? _roomId;
  final TextMessageContent? _description;
  final List<EventLocationInfo>? _locations;
  final int? _startTime;
  final int? _endTime;

  MockCalendarEvent({
    this.rsvpStatus,
    String? title,
    String? eventId,
    String? roomId,
    TextMessageContent? description,
    List<EventLocationInfo>? locations,
    int? startTime,
    int? endTime,
  }) : _title = title,
       _eventId = eventId,
       _roomId = roomId,
       _description = description,
       _locations = locations,
       _startTime = startTime,
       _endTime = endTime;

  @override
  String title() => _title ?? 'Test Event';

  @override
  EventId eventId() => a3sdk.MockEventId(id: _eventId ?? 'test-event-id');

  @override
  String roomIdStr() => _roomId ?? 'test-room-id';

  @override
  TextMessageContent? description() => _description;

  @override
  FfiListEventLocationInfo locations() =>
      MockFfiListEventLocationInfo(items: _locations ?? []);

  @override
  UtcDateTime utcStart() => a3sdk.MockUtcDateTime(
    millis: _startTime ?? DateTime.now().millisecondsSinceEpoch,
  );

  @override
  UtcDateTime utcEnd() => a3sdk.MockUtcDateTime(
    millis:
        _endTime ??
        (_startTime ?? DateTime.now().millisecondsSinceEpoch) + 3600000,
  );

  @override
  Future<RsvpManager> rsvps() async => MockRsvpManager();

  @override
  Future<OptionRsvpStatus> respondedByMe() async =>
      a3sdk.MockOptionRsvpStatus(rsvpStatus);
}

class MockCalendarEventDraft extends Mock implements CalendarEventDraft {}

class MockRsvpManager extends Mock implements RsvpManager {
  @override
  RsvpDraft rsvpDraft() => MockRsvpDraft();
}

class MockRsvpDraft extends Mock implements RsvpDraft {
  @override
  Future<EventId> send() async => a3sdk.MockEventId(id: 'test-rsvp-id');

  @override
  void status(String status) {}
}
