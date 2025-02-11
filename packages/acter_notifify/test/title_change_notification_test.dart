import 'package:acter_notifify/acter_notifify.dart';
import 'package:acter_notifify/l10n/l10n_en.dart';
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
    setActerNotififyL1On(ActerNotififyL10nEn());
  });

  setUp(() {
    //Mack declaration
    item = MockNotificationItem();
    parent = MockNotificationParent();

    //Set parent
    when(() => item.parent()).thenReturn(parent);

    //Set pushStyle
    when(() => item.pushStyle()).thenReturn(PushStyles.titleChange.name);
  });

  group("Title changes : Title and body generation ", () {
    test("Pin title change with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(MockObject.pin.name);
      when(() => parent.emoji()).thenReturn(MockObject.pin.emoji);
      when(() => parent.title()).thenReturn("The House");
      // Arrange: Set new title
      when(() => item.title()).thenReturn("The House WiFi");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Washington Johnson");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📌 The House renamed");
      expect(body, 'by Washington Johnson to "The House WiFi"');
    });
    test("Event title change with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Meet-up");
      // Arrange: Set new title
      when(() => item.title()).thenReturn("Social Hangout 2025");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Christine Knudsen");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "🗓️ Meet-up renamed");
      expect(body, 'by Christine Knudsen to "Social Hangout 2025"');
    });
    test("Task-List title change with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskList.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskList.emoji);
      when(() => parent.title()).thenReturn("2025 Goals");
      // Arrange: Set new title
      when(() => item.title()).thenReturn("New Year Goals");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Bernd Maur");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📋 2025 Goals renamed");
      expect(body, 'by Bernd Maur to "New Year Goals"');
    });

    test("Task-Item title change with parent info", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Deployment");
      // Arrange: Set new title
      when(() => item.title()).thenReturn("Product Deployment");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Thorsten Schweitzer");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "☑️ Website Deployment renamed");
      expect(body, 'by Thorsten Schweitzer to "Product Deployment"');
    });

    test("Title change with no parent", () {
      // Arrange: Set parent object data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      // Arrange: Set new title
      when(() => item.title()).thenReturn("Social Hangout 2025");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '@id:acter.global renamed title to "Social Hangout 2025"');
      expect(body, null);
    });
  });
}
