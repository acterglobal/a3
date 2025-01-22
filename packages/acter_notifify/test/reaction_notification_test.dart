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
    when(() => item.pushStyle()).thenReturn("reaction");

    //Set parent
    when(() => item.parent()).thenReturn(parent);

    //Set send user name
    final sender = MockNotificationSender(name: "Washington Johnson");
    when(() => item.sender()).thenReturn(sender);

    //Set message content
    msg = MockMsgContent(content: "This is great");
    when(() => item.body()).thenReturn(msg);
  });


  group("Title and Body generation", () {
    test("Reaction on boost", () {
      when(() => item.reactionKey()).thenReturn("❤️");
      when(() => parent.objectTypeStr()).thenReturn("news");
      when(() => parent.emoji()).thenReturn("🚀");
      final (title, body) = genTitleAndBody(item);
      expect(title, '"❤️" to 🚀 boost');
      expect(body, "Washington Johnson");
    });
    test("Reaction on Pin", () {
      when(() => parent.objectTypeStr()).thenReturn("pin");
      when(() => parent.emoji()).thenReturn("📌");
      when(() => item.reactionKey()).thenReturn("❤️");
      when(() => parent.title()).thenReturn("Candlesticks");
      final (title, body) = genTitleAndBody(item);
      expect(title, '"❤️" to 📌 Candlesticks');
      expect(body, "Washington Johnson");
    });
    test("Reaction with parent", () {
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);
      final (title, body) = genTitleAndBody(item);
      expect(title, '"❤️"');
      expect(body, "@id:acter.global");
    });
  });
}
