import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../mock_data/mock_activity.dart';

void main() {
  late ProviderContainer container;
  late List<MockActivity> mockActivities;

  setUp(() {
    container = ProviderContainer();
    mockActivities = [
      // Activities from different days
      MockActivity(
        mockType: 'comment',
        mockOriginServerTs: DateTime(2024, 3, 1, 12, 0).millisecondsSinceEpoch,
      ),
      MockActivity(
        mockType: 'reaction',
        mockOriginServerTs: DateTime(2024, 3, 2, 15, 30).millisecondsSinceEpoch,
      ),
      // Multiple activities from the same day
      MockActivity(
        mockType: 'attachment',
        mockOriginServerTs: DateTime(2024, 3, 3, 9, 0).millisecondsSinceEpoch,
      ),
      MockActivity(
        mockType: 'references',
        mockOriginServerTs: DateTime(2024, 3, 3, 14, 0).millisecondsSinceEpoch,
      ),
      // Activity from a different month
      MockActivity(
        mockType: 'comment',
        mockOriginServerTs:
            DateTime(2024, 2, 28, 23, 59).millisecondsSinceEpoch,
      ),
    ];
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'activityDatesProvider returns unique dates sorted in descending order',
    () async {
      // Override the allActivitiesProvider to return our mock activities
      container = ProviderContainer(
        overrides: [
          allActivitiesProvider.overrideWith((ref) => mockActivities),
        ],
      );

      // Get the dates from the provider
      final dates = await container.read(activityDatesProvider.future);

      // Verify the number of unique dates
      expect(dates.length, 4); // 4 unique days

      // Verify the dates are sorted in descending order
      expect(dates[0], DateTime(2024, 3, 3)); // Latest date
      expect(dates[1], DateTime(2024, 3, 2));
      expect(dates[2], DateTime(2024, 3, 1));
      expect(dates[3], DateTime(2024, 2, 28)); // Earliest date

      // Verify that multiple activities from the same day are deduplicated
      final march3rdActivities =
          dates
              .where(
                (date) => date.year == 2024 && date.month == 3 && date.day == 3,
              )
              .length;
      expect(march3rdActivities, 1);
    },
  );

  test('activityDatesProvider handles empty activity list', () async {
    // Override the allActivitiesProvider to return an empty list
    container = ProviderContainer(
      overrides: [allActivitiesProvider.overrideWith((ref) => [])],
    );

    // Get the dates from the provider
    final dates = await container.read(activityDatesProvider.future);

    // Verify empty list is returned
    expect(dates, isEmpty);
  });

  test(
    'activityDatesProvider handles activities with same timestamp',
    () async {
      final sameTimestamp = DateTime(2024, 3, 1, 12, 0).millisecondsSinceEpoch;
      final activitiesWithSameTimestamp = [
        MockActivity(mockType: 'comment', mockOriginServerTs: sameTimestamp),
        MockActivity(mockType: 'reaction', mockOriginServerTs: sameTimestamp),
      ];

      // Override the allActivitiesProvider
      container = ProviderContainer(
        overrides: [
          allActivitiesProvider.overrideWith(
            (ref) => activitiesWithSameTimestamp,
          ),
        ],
      );

      // Get the dates from the provider
      final dates = await container.read(activityDatesProvider.future);

      // Verify only one date is returned
      expect(dates.length, 1);
      expect(dates[0], DateTime(2024, 3, 1));
    },
  );
}
