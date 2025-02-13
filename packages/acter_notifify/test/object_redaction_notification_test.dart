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

    //Set pushStyle
    when(() => item.pushStyle()).thenReturn(PushStyles.redaction.name);
  });

  group("Object redaction : Title and body generation ", () {
    test("Pin redaction with parent info", () {
      // Arrange: Set parent object processing
      when(() => parent.typeStr()()).thenReturn(MockObject.pin.name);
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
      expect(title, "📌 The House removed");
      expect(body, 'by Washington Johnson from "Acter Global"');
    });
    test("Event redaction with parent info", () {
      // Arrange: Set parent object processing
      when(() => parent.typeStr()()).thenReturn(MockObject.event.name);
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
      expect(title, "🗓️ Meet-up removed");
      expect(body, 'by Christine Knudsen from "Acter Global"');
    });
    test("Task-List redaction with parent info", () {
      // Arrange: Set parent object processing
      when(() => parent.typeStr()()).thenReturn(MockObject.taskList.name);
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
      expect(title, "📋 2025 Goals removed");
      expect(body, 'by Bernd Maur from "Acter Global"');
    });

    test("Task-Item redaction with parent info", () {
      // Arrange: Set parent object processing
      when(() => parent.typeStr()()).thenReturn(MockObject.taskItem.name);
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
      expect(title, "☑️ Website Deployment removed");
      expect(body, 'by Thorsten Schweitzer from "Acter Global"');
    });

    test("Object redaction with no parent", () {
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      // Arrange: Set space name
      when(() => item.title()).thenReturn("Acter Global");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '@id:acter.global removed object from "Acter Global"');
      expect(body, null);
    });
  });
}
