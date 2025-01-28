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

    //Set pushStyle
    when(() => item.pushStyle()).thenReturn(PushStyles.attachment.name);
  });

  group("Title and body generation", () {
    test("Attachment on Pin", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(MockObject.pin.name);
      when(() => parent.emoji()).thenReturn(MockObject.pin.emoji);
      when(() => parent.title()).thenReturn("The house");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Washington Johnson");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set attachment title
      when(() => item.title()).thenReturn("Popular Websites");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📌 The house");
      expect(body, "Washington Johnson added 📎 Popular Websites");
    });

    test("Attachment on Event", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Social Hours 2025");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Bente Bang");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set attachment title
      when(() => item.title()).thenReturn("Venue Link");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "🗓️ Social Hours 2025");
      expect(body, "Bente Bang added 📎 Venue Link");
    });

    test("Attachment on Task-List", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskList.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskList.emoji);
      when(() => parent.title()).thenReturn("New Year Goals");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Patrick Andersen");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set attachment title
      when(() => item.title()).thenReturn("Research Data");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📋 New Year Goals");
      expect(body, "Patrick Andersen added 📎 Research Data");
    });

    test("Attachment on Task-Item", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Thorsten Schweitzer");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set attachment title
      when(() => item.title()).thenReturn("Design Research Data");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "☑️ Website Redesign");
      expect(body, "Thorsten Schweitzer added 📎 Design Research Data");
    });

    test("Attachment with no parent", () {
      // Arrange: Set parent object data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      // Arrange: Set attachment title
      when(() => item.title()).thenReturn("Social Profiles");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "@id:acter.global added 📎 Social Profiles");
      expect(body, null);
    });
  });
}
