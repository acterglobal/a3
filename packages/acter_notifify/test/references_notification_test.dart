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
    when(() => item.pushStyle()).thenReturn(PushStyles.references.name);
  });

  group("Title and body generation", () {
    test("Add reference on Pin", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.pin.name);
      when(() => parent.emoji()).thenReturn(MockObject.pin.emoji);
      when(() => parent.title()).thenReturn("The house");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Washington Johnson");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set reference object content
      when(() => item.title()).thenReturn("🗓️ Social Hours 2025");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📌 The house");
      expect(body, "Washington Johnson linked 🗓️ Social Hours 2025");
    });

    test("Add reference on Event", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      when(() => parent.title()).thenReturn("Social Hours 2025");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Bente Bang");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set reference object content
      when(() => item.title()).thenReturn("📌 The house");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "🗓️ Social Hours 2025");
      expect(body, "Bente Bang linked 📌 The house");
    });

    test("Add reference on Task-List", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskList.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskList.emoji);
      when(() => parent.title()).thenReturn("New Year Goals");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Patrick Andersen");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set reference object content
      when(() => item.title()).thenReturn("📌 The house");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "📋 New Year Goals");
      expect(body, "Patrick Andersen linked 📌 The house");
    });

    test("Add reference on Task-Item", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Thorsten Schweitzer");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set reference object content
      when(() => item.title()).thenReturn("📋 New Year Goals");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "☑️ Website Redesign");
      expect(body, "Thorsten Schweitzer linked 📋 New Year Goals");
    });

    test("Add reference with no parent", () {
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      // Arrange: Set reference object content
      when(() => item.title()).thenReturn("📌 The house");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "@id:acter.global linked 📌 The house");
      expect(body, null);
    });
  });
}
