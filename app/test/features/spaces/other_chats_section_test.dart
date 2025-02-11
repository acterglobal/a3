import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/features/space/widgets/space_sections/other_chats_section.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    required List<String> otherLocalChats,
    required List<SpaceHierarchyRoomInfo> otherRemoteChats,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        otherChatsProvider.overrideWith(
          (a, b) => (otherLocalChats, otherRemoteChats),
        ),
      ],
      child: const OtherChatsSection(spaceId: '!spaceId', limit: 3),
    );
  }

  group('Other Chats', () {
    testWidgets('Empty State', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        otherLocalChats: List<String>.empty(),
        otherRemoteChats: List<SpaceHierarchyRoomInfo>.empty(),
      );
      expect(find.byType(RoomCard), findsNothing);
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('With Local Chats Only', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        otherLocalChats: ['room1', 'room2'],
        otherRemoteChats: List<SpaceHierarchyRoomInfo>.empty(),
      );
      expect(find.byType(RoomCard), findsExactly(2));
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('With Remote Chats Only', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        otherLocalChats: [],
        otherRemoteChats: [
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
        otherLocalChats: ['room1', 'room2'],
        otherRemoteChats: [
          MockSpaceHierarchyRoomInfo(roomId: 'A', joinRule: 'Public'),
          MockSpaceHierarchyRoomInfo(roomId: 'B', joinRule: 'Public'),
          MockSpaceHierarchyRoomInfo(roomId: 'C', joinRule: 'Public'),
        ],
      );

      //Two Local + One Remote as limit is 3
      expect(find.byType(RoomCard), findsExactly(2));
      expect(find.byType(RoomHierarchyCard), findsExactly(1));
    });
  });
}
