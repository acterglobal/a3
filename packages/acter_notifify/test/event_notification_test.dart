import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_data/mock_notification_item.dart';
import 'mock_data/mock_notification_parent.dart';
import 'mock_data/mock_notification_sender.dart';
import 'mock_data/mock_object.dart';

void main() {
  late MockNotificationItem item;
  late MockNotificationParent parent;

  setUp(() {
    //Mack declaration
    item = MockNotificationItem();
    parent = MockNotificationParent();

    //Set parent
    when(() => item.parent()).thenReturn(parent);
  });

  group("Event date changes : Title and body generation ", () {
    test("Changes in event date with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.eventDateChange.name);
      // Arrange: Set new date
      when(() => item.title()).thenReturn("24 January, 2025");
      // Arrange: Set parent data
      when(() => parent.typeStr()()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Social Hours 2025");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Bernd Maur");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "🗓️ Social Hours 2025 rescheduled");
      expect(body, 'by Bernd Maur to "24 January, 2025"');
    });

    test("Changes in date Date with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.eventDateChange.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("24 January, 2025");
      // Arrange: Set parent data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '@id:acter.global rescheduled event to "24 January, 2025"');
      expect(body, null);
    });
  });

  group("Event RSVP Yes : Title and body generation ", () {
    test("Event RSVP Yes with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.rsvpYes.name);
      // Arrange: Set parent object processing
      when(() => parent.typeStr()()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Social Hours 2025");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Thorsten Schweitzer");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✅ Thorsten Schweitzer will join');
      expect(body, '🗓️ Social Hours 2025');
    });

    test("Event RSVP Yes with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.rsvpYes.name);
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✅ @id:acter.global will join');
      expect(body, null);
    });
  });
  group("Event RSVP Maybe : Title and body generation ", () {
    test("Event RSVP Maybe with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.rsvpMaybe.name);
      // Arrange: Set parent object processing
      when(() => parent.typeStr()()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Social Hours 2025");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Patrick Andersen");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✔️ Patrick Andersen might join');
      expect(body, '🗓️ Social Hours 2025');
    });

    test("Event RSVP Maybe with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.rsvpMaybe.name);
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✔️ @id:acter.global might join');
      expect(body, null);
    });
  });
  group("Event RSVP No : Title and body generation ", () {
    test("Event RSVP No with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.rsvpNo.name);
      // Arrange: Set parent object processing
      when(() => parent.typeStr()()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Social Hours 2025");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Christine Knudsen");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✖️ Christine Knudsen will not join');
      expect(body, '🗓️ Social Hours 2025');
    });

    test("Event RSVP No with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.rsvpNo.name);
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✖️ @id:acter.global will not join');
      expect(body, null);
    });
  });
}
