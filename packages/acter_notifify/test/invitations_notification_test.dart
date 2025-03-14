import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_data/mock_notification_item.dart';
import 'mock_data/mock_activity_object.dart';
import 'mock_data/mock_notification_sender.dart';
import 'mock_data/mock_object.dart';

class MockFfiString extends Mock implements FfiString {
  final String value;

  MockFfiString(this.value);

  @override
  String toDartString() => value;
}

class MockFfiListFfiString extends Mock implements FfiListFfiString {
  final List<String> strings;

  MockFfiListFfiString({this.strings = const []});

  @override
  int get length => strings.length;

  @override
  FfiString get first => MockFfiString(strings.first);
}

void main() {
  late MockNotificationItem item;
  late MockActivityObject parent;

  setUpAll(() {
    //Mack declaration
    item = MockNotificationItem();
    parent = MockActivityObject();

    //Set parent
    when(() => item.parent()).thenReturn(parent);
    when(() => parent.typeStr()).thenReturn(MockObject.taskItem.name);
    when(() => parent.emoji()).thenReturn(MockObject.taskItem.emoji);
    when(() => parent.title()).thenReturn("Website Redesign");

    //Set pushStyle
    when(() => item.pushStyle()).thenReturn(PushStyles.objectInvitation.name);
  });

  group("Object Invitation Notification", () {
    test("Invites you to task", () {
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Bernd Maur");
      when(() => item.sender()).thenReturn(sender);
      when(() => item.mentionsYou()).thenReturn(true);

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, '📨 Bernd Maur invited you');
      expect(body, "☑️ Website Redesign");
    });
    test("Invites you someone else to task", () {
      // Arrange: Set sender user name
      final sender = MockNotificationSender(name: "Michael May");
      when(() => item.sender()).thenReturn(sender);
      when(() => item.mentionsYou()).thenReturn(false);

      when(() => item.whom())
          .thenReturn(MockFfiListFfiString(strings: ["@id:acter.global"]));

      // Act: process processing and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "☑️ Website Redesign");
      expect(body, '📨 Michael May invited @id:acter.global');
    });
  });
}
