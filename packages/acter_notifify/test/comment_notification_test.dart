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
  late MockMsgContent msg;

  setUpAll(() {
    //Mack declaration
    item = MockNotificationItem();
    parent = MockNotificationParent();

    //Set parent
    when(() => item.parent()).thenReturn(parent);

    //Set pushStyle
    when(() => item.pushStyle()).thenReturn(PushStyles.comment.name);
  });

  group("Title and body generation", () {
    test("Comment on boost", () {
      // Arrange: Set parent object data
      when(() => parent.typeStr()()).thenReturn(MockObject.news.name);
      when(() => parent.emoji()).thenReturn(MockObject.news.emoji);
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Bernd Maur");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set comment content
      msg = MockMsgContent(content: "This is great");
      when(() => item.body()).thenReturn(msg);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Bernd Maur commented");
      expect(body, "On 🚀 boost: This is great");
    });

    test("Comment on Pin", () {
      // Arrange: Set parent data
      when(() => parent.typeStr()()).thenReturn(MockObject.pin.name);
      when(() => parent.emoji()).thenReturn(MockObject.pin.emoji);
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Thorsten Schweitzer");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set comment content
      msg = MockMsgContent(content: "This is crazy");
      when(() => item.body()).thenReturn(msg);

      // Act: process processing and get tile and body
      when(() => parent.title()).thenReturn("The house");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Thorsten Schweitzer commented");
      expect(body, "On 📌 The house: This is crazy");
    });

    test("Comment on Event", () {
      // Arrange: Set parent data
      when(() => parent.typeStr()()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Patrick Andersen");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set comment content
      msg = MockMsgContent(content: "Best time to get relaxed.");
      when(() => item.body()).thenReturn(msg);

      // Act: process processing and get tile and body
      when(() => parent.title()).thenReturn("Social Hours 2025");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Patrick Andersen commented");
      expect(body, "On 🗓️ Social Hours 2025: Best time to get relaxed.");
    });

    test("Comment on Task-List", () {
      // Arrange: Set parent data
      when(() => parent.typeStr()()).thenReturn(MockObject.taskList.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskList.emoji);
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Christine Knudsen");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set comment content
      msg = MockMsgContent(content: "This best way to manage goals");
      when(() => item.body()).thenReturn(msg);

      // Act: process processing and get tile and body
      when(() => parent.title()).thenReturn("New Year Goals");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Christine Knudsen commented");
      expect(body, "On 📋 New Year Goals: This best way to manage goals");
    });

    test("Comment on Task-Item", () {
      // Arrange: Set parent data
      when(() => parent.typeStr()()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Bente Bang");
      when(() => item.sender()).thenReturn(sender);
      // Arrange: Set comment content
      msg = MockMsgContent(content: "Finally!! I have completed it.");
      when(() => item.body()).thenReturn(msg);

      // Act: process processing and get tile and body
      when(() => parent.title()).thenReturn("Website Redesign");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Bente Bang commented");
      expect(body, "On ☑️ Website Redesign: Finally!! I have completed it.");
    });

    test("Comment with no parent", () {
      // Arrange: Set parent data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      // Arrange: Set comment content
      msg = MockMsgContent(content: "Love it!!");
      when(() => item.body()).thenReturn(msg);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 @id:acter.global commented");
      expect(body, "Love it!!");
    });
  });
}
