// Mock classes
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_event_providers.dart';

class MockSpace extends Mock implements Space {
  @override
  CalendarEventDraft calendarEventDraft() => MockCalendarEventDraft();
}

class MockCalendarEvent extends Mock implements CalendarEvent {
  @override
  String title() => 'Test Event';
  
  @override
  UtcDateTime utcStart() => MockUtcDateTime(millis: DateTime.now().millisecondsSinceEpoch);
  
  @override
  UtcDateTime utcEnd() => MockUtcDateTime(millis: DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch);
  
  @override
  String roomIdStr() => 'test-space-id';
  
  @override
  Future<RsvpManager> rsvps() async => MockRsvpManager();
  
  @override
  TextMessageContent? description() => null;
}

class MockCalendarEventDraft extends Mock implements CalendarEventDraft {
  @override
  Future<EventId> send() async => MockEventId('test-event-id');
  
  @override
  void title(String title) {}
  
  @override
  void utcStartFromRfc3339(String start) {}
  
  @override
  void utcEndFromRfc3339(String end) {}
  
  @override
  void descriptionHtml(String plain, String html) {}
  
  @override
  void addPhysicalLocation(String? name, String? description, String? address, String? city, String? country, String? postalCode, String? note) {}
  
  @override
  void addVirtualLocation(String? name, String? description, String? url, String note, String? type) {}
}

class MockRsvpManager extends Mock implements RsvpManager {
  @override
  RsvpDraft rsvpDraft() => MockRsvpDraft();
}

class MockRsvpDraft extends Mock implements RsvpDraft {
  @override
  Future<EventId> send() async => MockEventId('test-rsvp-id');
  
  @override
  void status(String status) {}
}

class MockUtcDateTime extends Mock implements UtcDateTime {
  final int millis;
  MockUtcDateTime({required this.millis});

  @override
  int timestampMillis() => millis;
}
