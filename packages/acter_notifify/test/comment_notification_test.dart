import 'package:acter_notifify/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_data/mock_notification_item.dart';
import 'mock_data/mock_notification_parent.dart';
import 'mock_data/mock_notification_sender.dart';

void main() {
  group("Title and body generation", () {
    test("Comment on boost", () {
      final item = MockNotificationItem();
      final parent = MockNotificationParent();
      final sender = MockNotificationSender(name: "Washington Simp");
      final msg = MockMsgContent(content: "This is great");
      when(() => item.pushStyle()).thenReturn("comment");
      when(() => item.parent()).thenReturn(parent);
      when(() => item.sender()).thenReturn(sender);
      when(() => item.body()).thenReturn(msg);
      when(() => parent.objectTypeStr()).thenReturn("news");
      when(() => parent.emoji()).thenReturn("🚀");
      final (title, body) = genTitleAndBody(item);
      expect(title, "💬 Comment on 🚀 boost");
      expect(body, "Washington Simp: This is great");
    });
    test("Comment on Pin", () {
      final item = MockNotificationItem();
      final parent = MockNotificationParent();
      final sender = MockNotificationSender(name: "User name");
      final msg = MockMsgContent(content: "Where can I find it?");
      when(() => item.pushStyle()).thenReturn("comment");
      when(() => item.parent()).thenReturn(parent);
      when(() => item.sender()).thenReturn(sender);
      when(() => item.body()).thenReturn(msg);
      when(() => parent.objectTypeStr()).thenReturn("pin");
      when(() => parent.emoji()).thenReturn("📌");
      when(() => parent.title()).thenReturn("The house");
      final (title, body) = genTitleAndBody(item);
      expect(title, "💬 Comment on 📌 The house");
      expect(body, "User name: Where can I find it?");
    });
    test("Comment with no parent", () {
      final item = MockNotificationItem();
      final msg = MockMsgContent(content: "This looks good");
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.body()).thenReturn(msg);
      when(() => item.sender()).thenReturn(sender);
      when(() => item.pushStyle()).thenReturn("comment");
      when(() => item.parent()).thenReturn(null);
      final (title, body) = genTitleAndBody(item);
      expect(title, "💬 Comment");
      expect(body, "@id:acter.global: This looks good");
    });
  });
}
