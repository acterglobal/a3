import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/features/space/widgets/space_sections/other_sub_spaces_section.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';
import 'utils.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    required List<String> otherLocalSpaces,
    required List<SpaceHierarchyRoomInfo> otherRemoteSpaces,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        ...spaceOverrides(),
        otherSubSpacesProvider.overrideWith(
          (a, b) => (otherLocalSpaces, otherRemoteSpaces),
        ),
        spaceProvider.overrideWith((a, b) => MockSpace()),
      ],
      child: const OtherSubSpacesSection(spaceId: '!spaceId', limit: 3),
    );
  }

  group('Other Spaces', () {
    testWidgets('Other Spaces - Empty State', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        otherLocalSpaces: List<String>.empty(),
        otherRemoteSpaces: List<SpaceHierarchyRoomInfo>.empty(),
      );
      expect(find.byType(RoomCard), findsNothing);
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('With Local Spaces Only', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        otherLocalSpaces: ['room1', 'room2'],
        otherRemoteSpaces: List<SpaceHierarchyRoomInfo>.empty(),
      );
      expect(find.byType(RoomCard), findsExactly(2));
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('With Remote Spaces Only', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        otherLocalSpaces: [],
        otherRemoteSpaces: [
          MockSpaceHierarchyRoomInfo(roomId: 'A', joinRule: 'Public'),
          MockSpaceHierarchyRoomInfo(roomId: 'B', joinRule: 'Public'),
        ],
      );
      expect(find.byType(RoomCard), findsNothing);
      expect(find.byType(RoomHierarchyCard), findsExactly(2));
    });

    testWidgets('With Both Local and Remote Spaces', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        otherLocalSpaces: ['room1', 'room2'],
        otherRemoteSpaces: [
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
