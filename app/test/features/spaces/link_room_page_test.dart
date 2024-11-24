import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/sheets/link_room_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_a3sdk.dart';
import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Link Room Page - chats', () {
    testWidgets('Only shows non-dm chats', (tester) async {
      final mockChatA = MockConvo('chat-a');
      final mockChatB = MockConvo('other-chat');
      final dmConvo = MockConvo('dm-chat');

      final mockedNames = {
        'chat-a': 'Mega super chat',
        'other-chat': 'Other cool chat',
        'dm-chat': 'Private DM chat',
      };

      when(() => mockChatA.isDm()).thenReturn(false);
      when(() => mockChatB.isDm()).thenReturn(false);
      when(() => dmConvo.isDm()).thenReturn(true); // should not show up

      await tester.pumpProviderWidget(
        overrides: [
          // mocking so we can display the page in general
          roomVisibilityProvider.overrideWith((a, b) => null),
          roomDisplayNameProvider.overrideWith((a, b) => mockedNames[b]),
          parentAvatarInfosProvider.overrideWith((a, b) => []),
          roomAvatarProvider.overrideWith((a, b) => null),
          roomAvatarInfoProvider
              .overrideWith(() => MockRoomAvatarInfoNotifier()),
          roomMembershipProvider.overrideWith((a, b) => null),
          spaceProvider.overrideWith((a, b) => MockSpace()),
          chatsProvider.overrideWith(
            (a) => [
              mockChatA,
              mockChatB,
              dmConvo,
            ],
          ),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) async => SpaceRelationsOverview(
              hasMore: false,
              knownSubspaces: [],
              knownChats: ['chat-a', 'unknown-item'],
              suggestedIds: [],
              mainParent: null,
              parents: [],
              otherRelations: [],
            ),
          ),
        ],
        child: const LinkRoomPage(
          parentSpaceId: '!spaceId',
          pageTitle: 'This should go away',
          childRoomType: ChildRoomType.chat,
        ),
      );
      expect(find.text('This should go away'), findsOne);
      // find the specific chat items being rendered
      expect(find.text('Mega super chat'), findsOne);
      expect(find.text('Other cool chat'), findsOne);
      // and the dm is not shown
      expect(find.text('Private DM chat'), findsNothing);
    });
  });

  group('Link Room Page - Spaces', () {
    testWidgets('Shows the other spaces', (tester) async {
      final parentSpace = MockSpace(id: 'parentSpace');
      final mockSpaceA = MockSpace(id: 'space-a');
      final mockSpaceB = MockSpace(id: 'other-space');
      final mockSpaceC = MockSpace(id: 'unlinked-space');

      final mockedNames = {
        'parentSpace': 'SpaceName',
        'space-a': 'Mega super space',
        'other-space': 'Other cool space',
        'unlinked-space': 'Unklinked space',
      };

      // when(() => mockSpaceA.isDm()).thenReturn(false);
      // when(() => mockSpaceB.isDm()).thenReturn(false);
      // when(() => dmConvo.isDm()).thenReturn(true); // should not show up

      await tester.pumpProviderWidget(
        overrides: [
          // mocking so we can display the page in general
          roomVisibilityProvider.overrideWith((a, b) => null),
          roomDisplayNameProvider.overrideWith((a, b) => mockedNames[b]),
          parentAvatarInfosProvider.overrideWith((a, b) => []),
          roomAvatarProvider.overrideWith((a, b) => null),
          roomAvatarInfoProvider
              .overrideWith(() => MockRoomAvatarInfoNotifier()),
          roomMembershipProvider.overrideWith((a, b) => null),
          spacesProvider.overrideWith(
            (a) =>
                MockSpaceListNotifiers([parentSpace, mockSpaceA, mockSpaceB]),
          ),
          spaceProvider.overrideWith(
            (a, b) => switch (b) {
              'parenSpace' => parentSpace,
              'space-a' => mockSpaceA,
              'mockSpaceB' => mockSpaceB,
              'unlinked-space' => mockSpaceC,
              _ => throw 'Room Not Found'
            },
          ),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) async => SpaceRelationsOverview(
              hasMore: false,
              knownSubspaces: ['space-a', 'other-space'],
              knownChats: [],
              suggestedIds: [],
              mainParent: null,
              parents: [],
              otherRelations: [],
            ),
          ),
        ],
        child: const LinkRoomPage(
          parentSpaceId: '!spaceId',
          pageTitle: 'This should go away',
          childRoomType: ChildRoomType.space,
        ),
      );
      expect(find.text('This should go away'), findsOne);
      // find the specific chat items being rendered
      expect(find.text('Mega super space'), findsOne);
      expect(find.byKey(Key('room-list-unlink-space-a')), findsOneWidget);
      expect(find.text('Other cool space'), findsOne);
      expect(find.byKey(Key('room-list-unlink-other-space')), findsOneWidget);

      // this isn't yet linked
      expect(find.text('Unklinked space'), findsOne);
      expect(find.byKey(Key('room-list-link-other-space')), findsOneWidget);
    });
  });
}
