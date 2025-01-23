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

    //Set send user name
    final sender = MockNotificationSender(name: "Washington Johnson");
    when(() => item.sender()).thenReturn(sender);

    //Set message content
    msg = MockMsgContent(content: "This is great");
    when(() => item.body()).thenReturn(msg);
  });

  group("Title and body generation", () {
    test("Comment on boost", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.news.name);
      when(() => parent.emoji()).thenReturn(MockObject.news.emoji);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Washington Johnson commented");
      expect(body, "On 🚀 boost: This is great");
    });

    test("Comment on Pin", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.pin.name);
      when(() => parent.emoji()).thenReturn(MockObject.pin.emoji);

      // Act: process processing and get tile and body
      when(() => parent.title()).thenReturn("The house");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Washington Johnson commented");
      expect(body, "On 📌 The house: This is great");
    });

    test("Comment on Event", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.event.name);
      when(() => parent.emoji()).thenReturn(MockObject.event.emoji);

      // Act: process processing and get tile and body
      when(() => parent.title()).thenReturn("Social Hours 2025");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Washington Johnson commented");
      expect(body, "On 🗓️ Social Hours 2025: This is great");
    });

    test("Comment on Task-List", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskList.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskList.emoji);

      // Act: process processing and get tile and body
      when(() => parent.title()).thenReturn("New Year Goals");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Washington Johnson commented");
      expect(body, "On 📋 New Year Goals: This is great");
    });

    test("Comment on Task-Item", () {
      // Arrange: Set parent object processing
      when(() => parent.objectTypeStr()).thenReturn(MockObject.taskItem.name);
      when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);

      // Act: process processing and get tile and body
      when(() => parent.title()).thenReturn("Website Redesign");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Washington Johnson commented");
      expect(body, "On ☑️ Website Redesign: This is great");
    });

    test("Comment with no parent", () {
      // Arrange: Set sender and parent object processing
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 @id:acter.global commented");
      expect(body, "This is great");
    });
  });
}
