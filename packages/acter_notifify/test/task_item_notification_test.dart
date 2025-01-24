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

  group("Task Item Completed: Title and body generation ", () {
    test("Task Item Completed  with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskComplete.name);
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("📋 Product TO-DO");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '🟢 Washington Johnson completed');
      expect(body, '☑️ Website Redesign of 📋 Product TO-DO');
    });

    test("Task Item Completed with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskComplete.name);
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '🟢 @id:acter.global completed Task');
      expect(body, null);
    });
  });

  group("Task Item Completed: Title and body generation ", () {
    test("Task Item Re-Open  with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskReOpen.name);
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("📋 Product TO-DO");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '🟢 Washington Johnson re-opened');
      expect(body, '☑️ Website Redesign of 📋 Product TO-DO');
    });

    test("Task Item Re-Open with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskReOpen.name);
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '🟢 @id:acter.global re-opened Task');
      expect(body, null);
    });
  });
  group("Task Item Accepted: Title and body generation ", () {
    test("Task Item Accepted  with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskAccept.name);
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("📋 Product TO-DO");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '🤝 Washington Johnson accepted');
      expect(body, '☑️ Website Redesign of 📋 Product TO-DO');
    });

    test("Task Item Accepted with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskAccept.name);
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '🤝 @id:acter.global accepted Task');
      expect(body, null);
    });
  });
  group("Task Item Declined: Title and body generation ", () {
    test("Task Item Declined  with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskDecline.name);
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("📋 Product TO-DO");

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✖️ Washington Johnson declined');
      expect(body, '☑️ Website Redesign of 📋 Product TO-DO');
    });

    test("Task Item Declined with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskDecline.name);
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✖️ @id:acter.global declined Task');
      expect(body, null);
    });
  });
}
