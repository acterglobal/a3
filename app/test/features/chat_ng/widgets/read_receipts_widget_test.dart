import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/read_receipts_widget.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_util.dart';

void main() {
  late MockTimelineEventItem mockItem;
  const testRoomId = 'test_room_id';

  setUp(() {
    mockItem = MockTimelineEventItem();
  });

  Future<void> createReadReceiptWidgetUnderTest({
    required WidgetTester tester,
    Map<String, int>? readReceipts,
    int showAvatarsLimit = 5,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        messageReadReceiptsProvider(
          mockItem,
        ).overrideWith((ref) => readReceipts ?? {}),
        memberAvatarInfoProvider.overrideWith(
          (ref, param) => AvatarInfo(
            uniqueId: param.userId,
            displayName: 'User ${param.userId}',
          ),
        ),
      ],
      child: ReadReceiptsWidget.group(
        item: mockItem,
        roomId: testRoomId,
        showAvatarsLimit: showAvatarsLimit,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ReadReceiptsWidget tests', () {
    testWidgets('displays correct number of avatars within limit', (
      tester,
    ) async {
      final readReceipts = {
        'user1': 1234567890,
        'user2': 1234567891,
        'user3': 1234567892,
      };

      await createReadReceiptWidgetUnderTest(
        tester: tester,
        readReceipts: readReceipts,
        showAvatarsLimit: 5,
      );

      // should show all 3 avatars since they're within the limit
      expect(find.byType(ActerAvatar), findsNWidgets(3));
      expect(find.byType(CircleAvatar), findsNothing); // no overflow indicator
    });

    testWidgets('displays overflow indicator when exceeding limit', (
      tester,
    ) async {
      final readReceipts = {
        'user1': 1234567890,
        'user2': 1234567891,
        'user3': 1234567892,
        'user4': 1234567893,
        'user5': 1234567894,
        'user6': 1234567895,
      };

      await createReadReceiptWidgetUnderTest(
        tester: tester,
        readReceipts: readReceipts,
        showAvatarsLimit: 5,
      );

      // should show 5 avatars plus the overflow indicator
      expect(find.byType(ActerAvatar), findsNWidgets(5));
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('handles empty read receipts', (tester) async {
      await createReadReceiptWidgetUnderTest(tester: tester, readReceipts: {});

      // should not show any avatars or overflow indicator
      expect(find.byType(ActerAvatar), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('respects custom avatar limit', (tester) async {
      final readReceipts = {
        'user1': 1234567890,
        'user2': 1234567891,
        'user3': 1234567892,
      };

      await createReadReceiptWidgetUnderTest(
        tester: tester,
        readReceipts: readReceipts,
        showAvatarsLimit: 2,
      );

      // should show 2 avatars plus overflow indicator
      expect(find.byType(ActerAvatar), findsNWidgets(2));
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
    });
  });
}
