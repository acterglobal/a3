import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import '../../helpers/mock_chat_providers.dart';
import '../../helpers/test_util.dart';

const Map<String, AvatarInfo> _roomsData = {
  'roomA': AvatarInfo(uniqueId: 'roomA', displayName: 'Room ABC'),
  'roomB': AvatarInfo(uniqueId: 'roomB', displayName: 'Room BCD'),
};

void main() {
  // Helper function to create the widget under test
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    required String roomId,
    EdgeInsets? padding,
  }) async {
    // Pump the widget into the test environment
    await tester.pumpProviderWidget(
      overrides: [
        roomAvatarInfoProvider.overrideWith(
          () => MockRoomAvatarInfoNotifier(avatarInfos: _roomsData),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RoomAvatarBuilder(
            roomId: roomId,
            padding: padding,
            avatarSize: 20,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'RoomAvatarBuilder renders the correct avatar with given padding',
    (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        padding: EdgeInsets.all(10),
      );
      await tester.pumpAndSettle();

      // Check if the avatar widget is displayed
      expect(find.byType(ActerAvatar), findsOneWidget);

      // Check if the padding is applied (verify with specific padding)
      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsOneWidget);

      final paddingWidget = tester.widget<Padding>(paddingFinder);
      expect(paddingWidget.padding, EdgeInsets.all(10));

      // Check if avatar size matches the one given
      final avatar = tester.widget<ActerAvatar>(find.byType(ActerAvatar));
      expect(avatar.options.size, 20);
    },
  );

  testWidgets('RoomAvatarBuilder renders the correct avatar without padding', (
    WidgetTester tester,
  ) async {
    await createWidgetUnderTest(tester: tester, roomId: 'room1');
    await tester.pumpAndSettle();
    // Check if the avatar widget is displayed
    expect(find.byType(ActerAvatar), findsOneWidget);

    // No padding should be applied
    expect(find.byType(Padding), findsNothing);

    // Check if avatar size matches the one given
    final avatar = tester.widget<ActerAvatar>(find.byType(ActerAvatar));
    expect(avatar.options.size, 20);
  });
}
