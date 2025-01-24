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

  setUpAll(() {
    //Mack declaration
    item = MockNotificationItem();
    parent = MockNotificationParent();

    //Set parent
    when(() => item.parent()).thenReturn(parent);

    //Set send user name
    final sender = MockNotificationSender(name: "Washington Johnson");
    when(() => item.sender()).thenReturn(sender);
  });

  group("Title and body generation for event date changes", () {
    test("Changes in event Date with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.eventDateChange.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("24 January, 2025");
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Social Hours 2025");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "🗓️ Social Hours 2025 rescheduled");
      expect(body, 'by Washington Johnson to "24 January, 2025"');
    });

    test("Changes in event Date without parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.eventDateChange.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("24 January, 2025");
      // Arrange: Set sender and parent object processing
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
}
