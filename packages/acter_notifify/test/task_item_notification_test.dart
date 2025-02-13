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

  group("Task Item Completed: Title and body generation ", () {
    test("Task Item Completed with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskComplete.name);
      // Arrange: Set parent object data
      when(() => parent.typeStr()()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("📋 Product TO-DO");
      // Arrange: Set send user name
      final sender = MockNotificationSender(name: "Washington Johnson");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '🟢 Washington Johnson completed');
      expect(body, '☑️ Website Redesign of 📋 Product TO-DO');
    });

    test("Task Item Completed with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskComplete.name);
      // Arrange: Set parent object data
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

  group("Task Item Re-Open: Title and body generation ", () {
    test("Task Item Re-Open with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskReOpen.name);
      // Arrange: Set parent object data
      when(() => parent.typeStr()()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("📋 Product TO-DO");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Thorsten Schweitzer");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '  ⃝  Thorsten Schweitzer re-opened');
      expect(body, '☑️ Website Redesign of 📋 Product TO-DO');
    });

    test("Task Item Re-Open with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskReOpen.name);
      // Arrange: Set parent object data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '  ⃝  @id:acter.global re-opened Task');
      expect(body, null);
    });
  });
  group("Task Item Accepted: Title and body generation ", () {
    test("Task Item Accepted with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskAccept.name);
      // Arrange: Set parent object data
      when(() => parent.typeStr()()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("📋 Product TO-DO");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Patrick Andersen");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '🤝 Patrick Andersen accepted');
      expect(body, '☑️ Website Redesign of 📋 Product TO-DO');
    });

    test("Task Item Accepted with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskAccept.name);
      // Arrange: Set parent object data
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
    test("Task Item Declined with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskDecline.name);
      // Arrange: Set parent object data
      when(() => parent.typeStr()()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("📋 Product TO-DO");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Christine Knudsen");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '✖️ Christine Knudsen declined');
      expect(body, '☑️ Website Redesign of 📋 Product TO-DO');
    });

    test("Task Item Declined with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle()).thenReturn(PushStyles.taskDecline.name);
      // Arrange: Set parent object data
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
  group("Task Item Due Date Change: Title and body generation ", () {
    test("Task Item Due Date Change with parent data", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle())
          .thenReturn(PushStyles.taskDueDateChange.name);
      // Arrange: Set parent object data
      when(() => parent.typeStr()()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      when(() => parent.title()).thenReturn("Website Redesign");
      when(() => item.title()).thenReturn("24 January, 2025");
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Bente Bang");
      when(() => item.sender()).thenReturn(sender);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '☑️ Website Redesign rescheduled');
      expect(body, 'by Bente Bang to "24 January, 2025"');
    });

    test("Task Item Due Date Change with no parent", () {
      // Arrange: Set pushStyle
      when(() => item.pushStyle())
          .thenReturn(PushStyles.taskDueDateChange.name);
      // Arrange: Set notification item
      when(() => item.title()).thenReturn("24 January, 2025");
      // Arrange: Set parent object data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '@id:acter.global rescheduled task to "24 January, 2025"');
      expect(body, null);
    });
  });
}
