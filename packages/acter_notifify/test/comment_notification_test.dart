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

    //Set pushStyle
    when(() => item.pushStyle()).thenReturn("comment");

    //Set parent
    when(() => item.parent()).thenReturn(parent);

    //Set send user name
    final sender = MockNotificationSender(name: "Washington Johnson");
    when(() => item.sender()).thenReturn(sender);

    //Set message content
    msg = MockMsgContent(content: "This is great");
    when(() => item.body()).thenReturn(msg);
  });

  group("Title and body generation", () {
    test("Comment on boost", () {
      when(() => parent.objectTypeStr()).thenReturn("news");
      when(() => parent.emoji()).thenReturn("🚀");
      final (title, body) = genTitleAndBody(item);
      expect(title, "💬 Comment on 🚀 boost");
      expect(body, "Washington Johnson: This is great");
    });
    test("Comment on Pin", () {
      when(() => parent.objectTypeStr()).thenReturn("pin");
      when(() => parent.emoji()).thenReturn("📌");
      when(() => parent.title()).thenReturn("The house");
      final (title, body) = genTitleAndBody(item);
      expect(title, "💬 Comment on 📌 The house");
      expect(body, "Washington Johnson: This is great");
    });
    test("Comment with no parent", () {
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      final (title, body) = genTitleAndBody(item);
      expect(title, "💬 Comment");
      expect(body, "@id:acter.global: This is great");
    });
  });
}
