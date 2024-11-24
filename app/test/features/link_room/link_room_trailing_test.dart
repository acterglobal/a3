import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/link_room/widgets/link_room_trailing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_room_providers.dart';
import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Link Room Action', () {
    testWidgets('Can not link', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [],
        child: const LinkRoomTrailing(
          parentId: 'parentSpace',
          roomId: 'space-a',
          canLink: false,
          isLinked: false,
        ),
      );

      await tester.pump();

      // no button found
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('Is linked', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [],
        child: const LinkRoomTrailing(
          parentId: 'parentSpace',
          roomId: 'space-a',
          canLink: false,
          isLinked: true,
        ),
      );

      await tester.pump();

      // no button found
      expect(find.byKey(Key('room-list-unlink-space-a')), findsOneWidget);
    });

    testWidgets('unlinks child space', (tester) async {
      final parentSpace = MockSpace(id: 'parentSpace');
      final mockRoom = MockRoom();

      when(() => parentSpace.removeChildRoom('child-space', any()))
          .thenAnswer((a) async => true);

      when(() => mockRoom.isSpace()).thenReturn(true);

      when(() => mockRoom.removeParentRoom('parentSpace', any()))
          .thenAnswer((a) async => true);

      await tester.pumpProviderWidget(
        overrides: [
          // mocking so we can display the page in general
          roomVisibilityProvider.overrideWith((a, b) => null),
          roomDisplayNameProvider.overrideWith((a, b) => null),
          parentAvatarInfosProvider.overrideWith((a, b) => []),
          roomAvatarProvider.overrideWith((a, b) => null),
          roomAvatarInfoProvider
              .overrideWith(() => MockRoomAvatarInfoNotifier()),
          roomMembershipProvider.overrideWith((a, b) => null),
          spacesProvider.overrideWith(
            (a) => MockSpaceListNotifiers([
              parentSpace,
            ]),
          ),
          spaceProvider.overrideWith(
            (a, b) => switch (b) {
              'parentSpace' => parentSpace,
              _ => throw 'Room Not Found'
            },
          ),
          maybeRoomProvider.overrideWith(
            () => MockAsyncMaybeRoomNotifier(
              items: {'child-space': mockRoom},
            ),
          ),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) async => SpaceRelationsOverview(
              hasMore: false,
              knownSubspaces: [],
              knownChats: [],
              suggestedIds: [],
              mainParent: null,
              parents: [],
              otherRelations: [],
            ),
          ),
        ],
        child: const LinkRoomTrailing(
          parentId: 'parentSpace',
          roomId: 'child-space',
          canLink: false,
          isLinked: true,
        ),
      );

      await tester.pump();

      // no button found
      final buttonFinder = find.byKey(Key('room-list-unlink-child-space'));
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);

      verify(() => parentSpace.removeChildRoom('child-space', any())).called(1);
      verify(() => mockRoom.removeParentRoom('parentSpace', any())).called(1);
    });

    testWidgets('unlinks child space', (tester) async {
      final parentSpace = MockSpace(id: 'parentSpace');
      final mockRoom = MockRoom();

      when(() => parentSpace.removeChildRoom('child-space', any()))
          .thenAnswer((a) async => true);

      when(() => mockRoom.isSpace()).thenReturn(true);

      when(() => mockRoom.removeParentRoom('parentSpace', any()))
          .thenAnswer((a) async => true);

      await tester.pumpProviderWidget(
        overrides: [
          // mocking so we can display the page in general
          roomVisibilityProvider.overrideWith((a, b) => null),
          roomDisplayNameProvider.overrideWith((a, b) => null),
          parentAvatarInfosProvider.overrideWith((a, b) => []),
          roomAvatarProvider.overrideWith((a, b) => null),
          roomAvatarInfoProvider
              .overrideWith(() => MockRoomAvatarInfoNotifier()),
          roomMembershipProvider.overrideWith((a, b) => null),
          spacesProvider.overrideWith(
            (a) => MockSpaceListNotifiers([
              parentSpace,
            ]),
          ),
          spaceProvider.overrideWith(
            (a, b) => switch (b) {
              'parentSpace' => parentSpace,
              _ => throw 'Room Not Found'
            },
          ),
          maybeRoomProvider.overrideWith(
            () => MockAsyncMaybeRoomNotifier(
              items: {'child-space': mockRoom},
            ),
          ),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) async => SpaceRelationsOverview(
              hasMore: false,
              knownSubspaces: [],
              knownChats: [],
              suggestedIds: [],
              mainParent: null,
              parents: [],
              otherRelations: [],
            ),
          ),
        ],
        child: const LinkRoomTrailing(
          parentId: 'parentSpace',
          roomId: 'child-space',
          canLink: false,
          isLinked: true,
        ),
      );

      await tester.pump();

      // no button found
      final buttonFinder = find.byKey(Key('room-list-unlink-child-space'));
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);

      verify(() => parentSpace.removeChildRoom('child-space', any())).called(1);
      verify(() => mockRoom.removeParentRoom('parentSpace', any())).called(1);
    });

    testWidgets('unlinks child chat', (tester) async {
      final parentSpace = MockSpace(id: 'parentSpace');
      final mockRoom = MockRoom();

      when(() => parentSpace.removeChildRoom('child-chat', any()))
          .thenAnswer((a) async => true);

      when(() => mockRoom.isSpace()).thenReturn(false);

      when(() => mockRoom.removeParentRoom('parentSpace', any()))
          .thenAnswer((a) async => true);

      await tester.pumpProviderWidget(
        overrides: [
          // mocking so we can display the page in general
          roomVisibilityProvider.overrideWith((a, b) => null),
          roomDisplayNameProvider.overrideWith((a, b) => null),
          parentAvatarInfosProvider.overrideWith((a, b) => []),
          roomAvatarProvider.overrideWith((a, b) => null),
          roomAvatarInfoProvider
              .overrideWith(() => MockRoomAvatarInfoNotifier()),
          roomMembershipProvider.overrideWith((a, b) => null),
          spacesProvider.overrideWith(
            (a) => MockSpaceListNotifiers([
              parentSpace,
            ]),
          ),
          spaceProvider.overrideWith(
            (a, b) => switch (b) {
              'parentSpace' => parentSpace,
              _ => throw 'Room Not Found'
            },
          ),
          maybeRoomProvider.overrideWith(
            () => MockAsyncMaybeRoomNotifier(
              items: {'child-chat': mockRoom},
            ),
          ),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) async => SpaceRelationsOverview(
              hasMore: false,
              knownSubspaces: [],
              knownChats: [],
              suggestedIds: [],
              mainParent: null,
              parents: [],
              otherRelations: [],
            ),
          ),
        ],
        child: const LinkRoomTrailing(
          parentId: 'parentSpace',
          roomId: 'child-chat',
          canLink: false,
          isLinked: true,
        ),
      );

      await tester.pump();

      // no button found
      final buttonFinder = find.byKey(Key('room-list-unlink-child-chat'));
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);

      verify(() => parentSpace.removeChildRoom('child-chat', any())).called(1);
      verify(() => mockRoom.removeParentRoom('parentSpace', any())).called(1);
    });
  });
}
