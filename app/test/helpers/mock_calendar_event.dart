// Mock classes
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

import '../features/activity/item_widgets/activity_event_item_widget_test.dart';
import 'mock_event_providers.dart';

class MockCalendarEvent extends Mock implements CalendarEvent {
  @override
  String title() => 'Test Event';
  
  @override
  UtcDateTime utcStart() => MockUtcDateTime();
  
  @override
  UtcDateTime utcEnd() => MockUtcDateTime();
  
  @override
  String roomIdStr() => 'test-space-id';
  
  @override
  Future<RsvpManager> rsvps() async => MockRsvpManager();
  
  @override
  TextMessageContent? description() => null;
}

class MockCalendarEventDraft extends Mock implements CalendarEventDraft {
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