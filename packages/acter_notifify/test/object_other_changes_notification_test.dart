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

    //Set pushStyle
    when(() => item.pushStyle()).thenReturn(PushStyles.otherChanges.name);
  });

  group("Object other changes : Title and body generation ", () {
    test("Pin other changes with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()).thenReturn(MockObject.pin.name);
      when(() => parent.emoji()).thenReturn(MockObject.pin.emoji);
      when(() => parent.title()).thenReturn("The House");
      // Arrange: Set space name
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Washington Johnson");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📌 The House updated");
      expect(body, 'by Washington Johnson');
    });
    test("Event other changes with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Meet-up");
      // Arrange: Set space name
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Christine Knudsen");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "🗓️ Meet-up updated");
      expect(body, 'by Christine Knudsen');
    });
    test("Task-List other changes with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()).thenReturn(MockObject.taskList.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskList.emoji);
      when(() => parent.title()).thenReturn("2025 Goals");
      // Arrange: Set space name
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Bernd Maur");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📋 2025 Goals updated");
      expect(body, 'by Bernd Maur');
    });

    test("Task-Item other changes with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Deployment");
      // Arrange: Set space name
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Thorsten Schweitzer");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "☑️ Website Deployment updated");
      expect(body, 'by Thorsten Schweitzer');
    });

    test("Object other changes with no parent", () {
      // Arrange: Set parent object data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      // Arrange: Set space name
      when(() => item.title()).thenReturn("Acter Global");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '@id:acter.global updated object');
      expect(body, null);
    });
  });
}
