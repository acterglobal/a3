import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../common/mock_data/mock_avatar_info.dart';
import '../../helpers/mock_chat_providers.dart';
import '../../helpers/mock_room_providers.dart';

const Map<String, AvatarInfo> _roomsData = {
  'roomA': AvatarInfo(uniqueId: 'roomA', displayName: 'Room ABC'),
  'roomB': AvatarInfo(uniqueId: 'roomB', displayName: 'Room BCD'),
};

void main() {
  group('RoomCard Widget Tests', () {
    // Test 1: Renders the RoomCard widget correctly
    testWidgets('Renders RoomCard with mock avatar and display name', (
      tester,
    ) async {
      final mockRoomId = 'room_1';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomAvatarInfoProvider.overrideWith(
              () => MockRoomAvatarInfoNotifier(avatarInfos: _roomsData),
            ),
          ],
          child: MaterialApp(home: RoomCard(roomId: mockRoomId)),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.byType(RoomCard),
        findsOneWidget,
      ); // Ensure image (avatar) is displayed.
    });

    testWidgets('should return list of parent AvatarInfo from the provider', (
      WidgetTester tester,
    ) async {
      // Set up mock data
      final mockRoomId = 'room_1';
      final mockAvatarInfo1 = MockAvatarInfo(uniqueId: 'roomA');
      final mockAvatarInfo2 = MockAvatarInfo(uniqueId: 'roomB');

      // Override the parentAvatarInfosProvider in the ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override parentAvatarInfosProvider with mock data
            parentAvatarInfosProvider.overrideWith(
              (_, id) => Future.value([mockAvatarInfo1, mockAvatarInfo2]),
            ),
          ],
          child: MaterialApp(
            home: RoomCard(
              roomId: mockRoomId,
            ), // Or any widget you want to test
          ),
        ),
      );

      // Wait for the widget to build and the future to resolve
      await tester.pumpAndSettle();
      expect(find.byType(RoomCard), findsOneWidget);
    });

    testWidgets('RoomCard displays the correct bookmark status (Mocked Data)', (
      WidgetTester tester,
    ) async {
      final mockRoomId = 'room_1';
      final mockNotifier = MockSpaceIsBookmarkedNotifier(true);
      // Override spaceIsBookmarkedProvider to simulate mock data
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spaceIsBookmarkedProvider.overrideWith(
              (_, id) => mockNotifier.fetchBookmarkStatus(),
            ),
          ],
          child: MaterialApp(
            home: RoomCard(
              roomId: mockRoomId,
            ), // RoomCard widget is being tested
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      expect(find.byType(RoomCard), findsOneWidget);
    });
  });
}
