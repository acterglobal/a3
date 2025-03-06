import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../mock_data/mock_activity.dart';

void main() {
  late ProviderContainer container;
  late List<MockActivity> mockActivities;

  setUp(() {
    container = ProviderContainer();
    mockActivities = [
      // Activities from different rooms on the same day
      MockActivity(
        mockType: 'comment',
        mockOriginServerTs: DateTime(2024, 3, 1, 12, 0).millisecondsSinceEpoch,
        mockRoomId: 'room-1',
      ),
      MockActivity(
        mockType: 'reaction',
        mockOriginServerTs: DateTime(2024, 3, 1, 15, 30).millisecondsSinceEpoch,
        mockRoomId: 'room-2',
      ),
      // Multiple activities from the same room on the same day
      MockActivity(
        mockType: 'attachment',
        mockOriginServerTs: DateTime(2024, 3, 1, 9, 0).millisecondsSinceEpoch,
        mockRoomId: 'room-1',
      ),
      // Activity from a different day
      MockActivity(
        mockType: 'references',
        mockOriginServerTs: DateTime(2024, 3, 2, 14, 0).millisecondsSinceEpoch,
        mockRoomId: 'room-3',
      ),
    ];
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'roomIdsByDateProvider returns unique room IDs for a specific date',
    () async {
      // Override the allActivitiesProvider to return our mock activities
      container = ProviderContainer(
        overrides: [
          allActivitiesProvider.overrideWith((ref) => mockActivities),
        ],
      );

      // Get the room IDs for March 1st, 2024
      final march1st = DateTime(2024, 3, 1);
      final roomIds = await container.read(
        roomIdsByDateProvider(march1st).future,
      );

      // Verify the number of unique room IDs
      expect(roomIds.length, 2); // room-1 and room-2

      // Verify the room IDs are correct
      expect(roomIds, contains('room-1'));
      expect(roomIds, contains('room-2'));

      // Verify room-1 is only included once despite having multiple activities
      expect(roomIds.where((id) => id == 'room-1').length, 1);
    },
  );

  test('roomIdsByDateProvider handles empty activity list', () async {
    // Override the allActivitiesProvider to return an empty list
    container = ProviderContainer(
      overrides: [allActivitiesProvider.overrideWith((ref) => [])],
    );

    // Get the room IDs for any date
    final date = DateTime(2024, 3, 1);
    final roomIds = await container.read(roomIdsByDateProvider(date).future);

    // Verify empty list is returned
    expect(roomIds, isEmpty);
  });

  test(
    'roomIdsByDateProvider handles activities with same timestamp',
    () async {
      final sameTimestamp = DateTime(2024, 3, 1, 12, 0).millisecondsSinceEpoch;
      final activitiesWithSameTimestamp = [
        MockActivity(
          mockType: 'comment',
          mockOriginServerTs: sameTimestamp,
          mockRoomId: 'room-1',
        ),
        MockActivity(
          mockType: 'reaction',
          mockOriginServerTs: sameTimestamp,
          mockRoomId: 'room-2',
        ),
      ];

      // Override the allActivitiesProvider
      container = ProviderContainer(
        overrides: [
          allActivitiesProvider.overrideWith(
            (ref) => activitiesWithSameTimestamp,
          ),
        ],
      );

      // Get the room IDs for March 1st, 2024
      final march1st = DateTime(2024, 3, 1);
      final roomIds = await container.read(
        roomIdsByDateProvider(march1st).future,
      );

      // Verify both room IDs are returned
      expect(roomIds.length, 2);
      expect(roomIds, contains('room-1'));
      expect(roomIds, contains('room-2'));
    },
  );
}
