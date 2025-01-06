import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/matrix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationItem extends Mock implements NotificationItem {}

class MockNotificationSender extends Mock implements NotificationSender {}

class MockNotificationParent extends Mock implements NotificationItemParent {}
// class MockNotificationItem extends Mock implements NotificationItem {}

void main() {
  group("title and body generation", () {
    group("comments", () {
      test("for boost", () {
        final item = MockNotificationItem();
        final parent = MockNotificationParent();
        when(() => item.pushStyle()).thenReturn("comment");
        when(() => item.parent()).thenReturn(parent);
        when(() => parent.objectTypeStr()).thenReturn("news");
        when(() => parent.emoji()).thenReturn("🚀");
        final (title, body) = genTitleAndBody(item);
        expect(title, "💬 Comment on 🚀 boost");
      });
    });

    test("fallback", () {});
  });
  test('import smoketest', () {
    // doesn’t do anything
  });
}
