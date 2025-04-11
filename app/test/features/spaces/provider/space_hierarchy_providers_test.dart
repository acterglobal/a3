import 'package:flutter_test/flutter_test.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:riverpod/riverpod.dart';

import '../../../helpers/mock_relations.dart';
import '../../../helpers/mock_room_providers.dart';
import '../../../helpers/mock_space_providers.dart';

void main() {
  group('Space Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('spaceRelationsOverviewProvider', () {
      test('returns correct overview with subspaces and chats', () async {
        // Create mock relations with subspaces and chats
        final mockRelations = MockSpaceRelations(
          roomId: 'space1',
          children: [
            MockSpaceRelation(roomId: 'subspace1', targetType: 'Space'),
            MockSpaceRelation(roomId: 'chat1', targetType: 'ChatRoom'),
            MockSpaceRelation(
              roomId: 'suggested1',
              targetType: 'Space',
              suggested: true,
            ),
          ],
        );

        // Mock providers
        container = ProviderContainer(
          overrides: [
            spaceRelationsProvider(
              'space1',
            ).overrideWith((ref) async => mockRelations),
            maybeRoomProvider.overrideWith(
              () => MockAsyncMaybeRoomNotifier(
                items: {
                  'subspace1': MockRoom(isJoined: true),
                  'chat1': MockRoom(isJoined: true),
                  'suggested1': MockRoom(isJoined: true),
                },
              ),
            ),
          ],
        );

        // cached
        // ignore: unused_local_variable
        final e = container.read(maybeRoomProvider('subspace1').future);
        // ignore: unused_local_variable
        final f = container.read(maybeRoomProvider('chat1').future);
        // ignore: unused_local_variable
        final g = container.read(maybeRoomProvider('suggested1').future);

        final result = await container.read(
          spaceRelationsOverviewProvider('space1').future,
        );

        expect(result.knownSubspaces, contains('subspace1'));
        expect(result.knownChats, contains('chat1'));
        expect(result.suggestedIds, contains('suggested1'));
        expect(result.hasMore, isFalse);
      });

      test('handles main parent and other parents correctly', () async {
        // Create mock relations with parents
        final mockRelations = MockSpaceRelations(
          roomId: 'space1',
          mainParent: MockSpaceRelation(
            roomId: 'mainParent',
            targetType: 'Space',
          ),
          otherParents: [
            MockSpaceRelation(roomId: 'otherParent1', targetType: 'Space'),
            MockSpaceRelation(roomId: 'chatParent', targetType: 'ChatRoom'),
          ],
        );

        // Mock providers
        container = ProviderContainer(
          overrides: [
            spaceRelationsProvider(
              'space1',
            ).overrideWith((ref) async => mockRelations),

            maybeRoomProvider.overrideWith(
              () => MockAsyncMaybeRoomNotifier(
                items: {
                  'chatParent': MockRoom(isJoined: true),
                  'mainParent': MockRoom(isJoined: true),
                  'otherParent1': MockRoom(isJoined: true),
                },
              ),
            ),
            spaceProvider('mainParent').overrideWith(
              (ref) => MockSpace(id: 'mainParent', isJoined: true),
            ),
            spaceProvider('otherParent1').overrideWith(
              (ref) => MockSpace(id: 'otherParent1', isJoined: true),
            ),
          ],
        );

        // cache
        // ignore: unused_local_variable
        final a = container.read(maybeRoomProvider('chatParent').future);
        // ignore: unused_local_variable
        final b = container.read(maybeRoomProvider('mainParent').future);
        // ignore: unused_local_variable
        final c = container.read(maybeRoomProvider('otherParent1').future);

        final result = await container.read(
          spaceRelationsOverviewProvider('space1').future,
        );

        expect(result.mainParent?.getRoomIdStr(), equals('mainParent'));
        expect(
          result.parents.map((p) => p.getRoomIdStr()),
          contains('otherParent1'),
        );
        expect(
          result.parents.map((p) => p.getRoomIdStr()),
          isNot(contains('chatParent')),
        );
      });

      test('sets hasMore when unknown rooms are present', () async {
        // Create mock relations with unknown rooms
        final mockRelations = MockSpaceRelations(
          roomId: 'space1',
          children: [
            MockSpaceRelation(roomId: 'knownRoom', targetType: 'Space'),
            MockSpaceRelation(roomId: 'unknownRoom', targetType: 'Space'),
          ],
        );

        // Mock providers - only provide the known room
        container = ProviderContainer(
          overrides: [
            spaceRelationsProvider(
              'space1',
            ).overrideWith((ref) async => mockRelations),
            maybeRoomProvider.overrideWith(
              () => MockAsyncMaybeRoomNotifier(
                items: {'knownRoom': MockRoom(isJoined: true)},
              ),
            ),
          ],
        );

        // ignore: unused_local_variable
        final a = container.read(maybeRoomProvider('knownRoom').future);

        final result = await container.read(
          spaceRelationsOverviewProvider('space1').future,
        );

        expect(result.hasMore, isTrue);
        expect(result.knownSubspaces, contains('knownRoom'));
        expect(result.knownSubspaces, isNot(contains('unknownRoom')));
      });
    });
  });
}
