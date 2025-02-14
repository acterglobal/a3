import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_data/mock_notification_item.dart';
import 'mock_data/mock_activity_object.dart';
import 'mock_data/mock_notification_sender.dart';
import 'mock_data/mock_object.dart';

void main() {
  late MockNotificationItem item;
  late MockActivityObject parent;

  setUp(() {
    //Mack declaration
    item = MockNotificationItem();
    parent = MockActivityObject();

    //Set parent
    when(() => item.parent()).thenReturn(parent);

    // Arrange: Set pushStyle
    when(() => item.pushStyle()).thenReturn(PushStyles.descriptionChange.name);
  });

  group("Description changes : Title and body generation ", () {
    test("Pin description change with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()).thenReturn(MockObject.pin.name);
      when(() => parent.emoji()).thenReturn(MockObject.pin.emoji);
      when(() => parent.title()).thenReturn("The House");
      // Arrange: Set new description
      when(() => item.title())
          .thenReturn("Lorem Ipsum is simply dummy text of the printing");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Washington Johnson");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📌 The House changed");
      expect(body,
          'Washington Johnson updated description: "Lorem Ipsum is simply dummy text of the printing"');
    });
    test("Event description change with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Meet-up");
      // Arrange: Set new description
      when(() => item.title())
          .thenReturn("Lorem Ipsum is simply dummy text of the printing");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Christine Knudsen");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "🗓️ Meet-up changed");
      expect(body,
          'Christine Knudsen updated description: "Lorem Ipsum is simply dummy text of the printing"');
    });
    test("Task-List description change with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()).thenReturn(MockObject.taskList.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskList.emoji);
      when(() => parent.title()).thenReturn("2025 Goals");
      // Arrange: Set new description
      when(() => item.title())
          .thenReturn("Lorem Ipsum is simply dummy text of the printing");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Bernd Maur");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📋 2025 Goals changed");
      expect(body,
          'Bernd Maur updated description: "Lorem Ipsum is simply dummy text of the printing"');
    });

    test("Task-Item description change with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Deployment");
      // Arrange: Set new description
      when(() => item.title())
          .thenReturn("Lorem Ipsum is simply dummy text of the printing");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Thorsten Schweitzer");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "☑️ Website Deployment changed");
      expect(body,
          'Thorsten Schweitzer updated description: "Lorem Ipsum is simply dummy text of the printing"');
    });

    test("Description change with no parent", () {
      // Arrange: Set parent object data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      // Arrange: Set new description
      when(() => item.title())
          .thenReturn("Lorem Ipsum is simply dummy text of the printing");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title,
          '@id:acter.global updated description: "Lorem Ipsum is simply dummy text of the printing"');
      expect(body, null);
    });
  });
}
