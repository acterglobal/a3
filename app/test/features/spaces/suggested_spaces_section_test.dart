import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/features/space/widgets/space_sections/suggested_spaces_section.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    required List<String> suggestedLocalSpaces,
    required List<SpaceHierarchyRoomInfo> suggestedRemoteSpaces,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        suggestedSpacesProvider.overrideWith(
          (a, b) => (suggestedLocalSpaces, suggestedRemoteSpaces),
        ),
      ],
      child: const SuggestedSpacesSection(spaceId: '!spaceId', limit: 3),
    );
  }

  group('Suggested Spaces', () {
    testWidgets('Empty State', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        suggestedLocalSpaces: List<String>.empty(),
        suggestedRemoteSpaces: List<SpaceHierarchyRoomInfo>.empty(),
      );
      expect(find.byType(RoomCard), findsNothing);
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('With Local Spaces Only', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        suggestedLocalSpaces: ['room1', 'room2'],
        suggestedRemoteSpaces: List<SpaceHierarchyRoomInfo>.empty(),
      );
      expect(find.byType(RoomCard), findsExactly(2));
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('With Remote Spaces Only', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        suggestedLocalSpaces: [],
        suggestedRemoteSpaces: [
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
        suggestedLocalSpaces: ['room1', 'room2'],
        suggestedRemoteSpaces: [
          MockSpaceHierarchyRoomInfo(roomId: 'A', joinRule: 'Public'),
          MockSpaceHierarchyRoomInfo(roomId: 'B', joinRule: 'Public'),
        ],
      );
      expect(find.byType(RoomCard), findsExactly(2));
      expect(find.byType(RoomHierarchyCard), findsExactly(2));
    });
  });
}
