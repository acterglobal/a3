import 'package:acter_notifify/data/data_contants.dart';
import 'package:acter_notifify/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_data/mock_notification_item.dart';
import 'mock_data/mock_notification_parent.dart';
import 'mock_data/mock_notification_sender.dart';

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
    when(() => item.pushStyle()).thenReturn(PushStyles.reaction.name);

    //Set send user name
    final sender = MockNotificationSender(name: "Washington Johnson");
    when(() => item.sender()).thenReturn(sender);

    //Set message content
    msg = MockMsgContent(content: "This is great");
    when(() => item.body()).thenReturn(msg);
  });

  group("Title and Body generation", () {
    test("Reaction on boost", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(ActerObject.news.name);
      when(() => parent.emoji()).thenReturn(ActerObject.news.emoji);

      // Arrange: Set reaction data
      when(() => item.reactionKey()).thenReturn(PushStyles.reaction.emoji);

      // Act: process data and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '"❤️" to 🚀 boost');
      expect(body, "Washington Johnson");
    });

    test("Reaction on Pin", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(ActerObject.pin.name);
      when(() => parent.emoji()).thenReturn(ActerObject.pin.emoji);
      when(() => parent.title()).thenReturn("Candlesticks");

      // Arrange: Set reaction data
      when(() => item.reactionKey()).thenReturn(PushStyles.reaction.emoji);

      // Act: process data and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '"❤️" to 📌 Candlesticks');
      expect(body, "Washington Johnson");
    });
    test("Reaction with parent", () {
      // Arrange: Set sender and parent object data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process data and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '"❤️"');
      expect(body, "@id:acter.global");
    });
  });
}
