import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/room/room_profile_header.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import '../../helpers/mock_chat_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  setUp(() {
    registerFallbackValue(MockRoomAvatarInfoNotifier());
  });

  // Helper function to create the widget under test
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    required String roomId,
  }) async {
    final mockedRoomData = <String, AvatarInfo>{
      roomId: AvatarInfo(
        uniqueId: roomId,
        displayName: 'Room $roomId',
        avatar: NetworkImage('https://example.com/avatar/$roomId.jpg'),
      ),
    };
    // Mock notifier
    final mockNotifier = MockRoomAvatarInfoNotifier(
      avatarInfos: mockedRoomData,
    );
    await tester.pumpProviderWidget(
      overrides: [roomAvatarInfoProvider.overrideWith(() => mockNotifier)],
      child: RoomProfileHeader(roomId: roomId),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'displays avatar and display name when avatar info is available',
    (tester) async {
      // Arrange
      const roomId = '123';
      // Act
      await createWidgetUnderTest(tester: tester, roomId: roomId);
      // Assert
      // Check that the avatar is displayed
      expect(find.byType(ActerAvatar), findsOneWidget);
      // Check that the display name is correctly displayed
      expect(find.text('Room $roomId'), findsOneWidget);
    },
  );
}
