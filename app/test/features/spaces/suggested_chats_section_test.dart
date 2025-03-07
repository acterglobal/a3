import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/features/space/widgets/space_sections/suggested_chats_section.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    required List<String> suggestedLocalChats,
    required List<SpaceHierarchyRoomInfo> suggestedRemoteChats,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        suggestedChatsProvider.overrideWith(
          (a, b) => (suggestedLocalChats, suggestedRemoteChats),
        ),
      ],
      child: const SuggestedChatsSection(spaceId: '!spaceId', limit: 3),
    );
  }

  group('Suggested Chats', () {
    testWidgets('Suggested Chats - Empty State', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        suggestedLocalChats: List<String>.empty(),
        suggestedRemoteChats: List<SpaceHierarchyRoomInfo>.empty(),
      );
      expect(find.byType(RoomCard), findsNothing);
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('With Local Chats Only', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        suggestedLocalChats: ['room1', 'room2'],
        suggestedRemoteChats: List<SpaceHierarchyRoomInfo>.empty(),
      );
      expect(find.byType(RoomCard), findsExactly(2));
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('With Remote Chats Only', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        suggestedLocalChats: [],
        suggestedRemoteChats: [
          MockSpaceHierarchyRoomInfo(roomId: 'A', joinRule: 'Public'),
          MockSpaceHierarchyRoomInfo(roomId: 'B', joinRule: 'Public'),
        ],
      );
      expect(find.byType(RoomCard), findsNothing);
      expect(find.byType(RoomHierarchyCard), findsExactly(2));
    });

    testWidgets('With Both Local and Remote Chat', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        suggestedLocalChats: ['room1', 'room2'],
        suggestedRemoteChats: [
          MockSpaceHierarchyRoomInfo(roomId: 'A', joinRule: 'Public'),
          MockSpaceHierarchyRoomInfo(roomId: 'B', joinRule: 'Public'),
        ],
      );
      expect(find.byType(RoomCard), findsExactly(2));
      expect(find.byType(RoomHierarchyCard), findsExactly(2));
    });
  });
}
