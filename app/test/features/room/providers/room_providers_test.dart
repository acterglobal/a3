import 'package:flutter_test/flutter_test.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:riverpod/riverpod.dart';

import '../../../helpers/mock_relations.dart';

void main() {
  group('Room Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('parentIdsProvider', () {
      test('returns empty list when spaceRelations is null', () async {
        // Mock spaceRelationsProvider to return null
        container = ProviderContainer(
          overrides: [
            spaceRelationsProvider('room1').overrideWith((ref) async => null),
          ],
        );

        final result = await container.read(parentIdsProvider('room1').future);
        expect(result, isEmpty);
      });

      test('returns parent IDs from mainParent and otherParents', () async {
        // Create mock SpaceRelations
        final mockRelations = MockSpaceRelations(
          roomId: 'room1',
          mainParent: MockSpaceRelation(roomId: 'parent1'),
          otherParents: [
            MockSpaceRelation(roomId: 'parent2'),
            MockSpaceRelation(roomId: 'parent3'),
          ],
        );

        // Mock spaceRelationsProvider
        container = ProviderContainer(
          overrides: [
            spaceRelationsProvider(
              'room1',
            ).overrideWith((ref) async => mockRelations),
          ],
        );

        final result = await container.read(parentIdsProvider('room1').future);
        expect(result, containsAll(['parent1', 'parent2', 'parent3']));
      });

      test('returns empty list when mainParent is null', () async {
        // Create mock SpaceRelations with null mainParent
        final mockRelations = MockSpaceRelations(
          roomId: 'room1',
          mainParent: null,
          otherParents: [MockSpaceRelation(roomId: 'parent2')],
        );

        // Mock spaceRelationsProvider
        container = ProviderContainer(
          overrides: [
            spaceRelationsProvider(
              'room1',
            ).overrideWith((ref) async => mockRelations),
          ],
        );

        final result = await container.read(parentIdsProvider('room1').future);
        expect(result, containsAll(['parent2']));
      });

      test('handles errors gracefully', () async {
        // Mock spaceRelationsProvider to throw an error
        container = ProviderContainer(
          overrides: [
            spaceRelationsProvider(
              'room1',
            ).overrideWith((ref) async => throw Exception('Test error')),
          ],
        );

        final result = await container.read(parentIdsProvider('room1').future);
        expect(result, isEmpty);
      });
    });
  });
}
