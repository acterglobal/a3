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

    //Set send user name
    final sender = MockNotificationSender(name: "Washington Johnson");
    when(() => item.sender()).thenReturn(sender);
  });

  group("Title changes : Title and body generation ", () {
    test("Pin title with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.otherChanges.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.pin.name);
      when(() => parent.emoji()).thenReturn(MockObject.pin.emoji);
      when(() => parent.title()).thenReturn("The House");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📌 The House updated");
      expect(body, 'by Washington Johnson');
    });
    test("Event title with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.otherChanges.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Meet-up");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "🗓️ Meet-up updated");
      expect(body, 'by Washington Johnson');
    });
    test("Task-List title with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.otherChanges.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskList.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskList.emoji);
      when(() => parent.title()).thenReturn("2025 Goals");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📋 2025 Goals updated");
      expect(body, 'by Washington Johnson');
    });

    test("Task-Item title with parent info", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.otherChanges.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Deployment");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "☑️ Website Deployment updated");
      expect(body, 'by Washington Johnson');
    });

    test("Title with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.otherChanges.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("Acter Global");
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '@id:acter.global updated object');
      expect(body, null);
    });
  });
}
