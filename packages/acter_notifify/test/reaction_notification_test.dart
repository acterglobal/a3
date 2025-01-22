import 'package:acter_notifify/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_data/mock_notification_item.dart';
import 'mock_data/mock_notification_parent.dart';
import 'mock_data/mock_notification_sender.dart';

void main() {
  group("Title and Body generation", () {
    test("Reaction on boost", () {
      final item = MockNotificationItem();
      final parent = MockNotificationParent();
      final sender = MockNotificationSender(name: "Michael Joker");
      when(() => item.pushStyle()).thenReturn("reaction");
      when(() => item.parent()).thenReturn(parent);
      when(() => item.sender()).thenReturn(sender);
      when(() => item.reactionKey()).thenReturn("❤️");
      when(() => parent.objectTypeStr()).thenReturn("news");
      when(() => parent.emoji()).thenReturn("🚀");
      final (title, body) = genTitleAndBody(item);
      expect(title, '"❤️" to 🚀 boost');
      expect(body, "Michael Joker");
    });
    test("Reaction on Pin", () {
      final item = MockNotificationItem();
      final parent = MockNotificationParent();
      final sender = MockNotificationSender(name: "User name");
      when(() => item.pushStyle()).thenReturn("reaction");
      when(() => item.parent()).thenReturn(parent);
      when(() => item.sender()).thenReturn(sender);
      when(() => parent.objectTypeStr()).thenReturn("pin");
      when(() => parent.emoji()).thenReturn("📌");
      when(() => item.reactionKey()).thenReturn("❤️");
      when(() => parent.title()).thenReturn("Candlesticks");
      final (title, body) = genTitleAndBody(item);
      expect(title, '"❤️" to 📌 Candlesticks');
      expect(body, "User name");
    });
    test("Reaction with parent", () {
      final item = MockNotificationItem();
      final msg = MockMsgContent(content: "This looks good");
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.body()).thenReturn(msg);
      when(() => item.sender()).thenReturn(sender);
      when(() => item.pushStyle()).thenReturn("reaction");
      when(() => item.parent()).thenReturn(null);
      final (title, body) = genTitleAndBody(item);
      expect(title, '"❤️"');
      expect(body, "@id:acter.global");
    });
  });
}
