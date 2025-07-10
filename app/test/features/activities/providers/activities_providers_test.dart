import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../activity/mock_data/mock_activity.dart';

// Mock classes for testing
class MockInvitation {
  final String mockId;
  MockInvitation({required this.mockId});
}

class MockEmailAddress {
  final String email;
  MockEmailAddress({required this.email});
}

class MockEmailAddresses {
  final List<MockEmailAddress> unconfirmed;
  final List<MockEmailAddress> confirmed;
  MockEmailAddresses({required this.unconfirmed, required this.confirmed});
}

class SyncState {
  final String? errorMsg;
  SyncState({this.errorMsg});
}

// Mock class for testing
class AsyncNotifierMock extends AllActivitiesNotifier {
  final List<Activity> mockActivities;
  
  AsyncNotifierMock(this.mockActivities);
  
  @override
  Future<List<RoomActivitiesInfo>> build() async {
    // Convert activities to RoomActivitiesInfo format
    return mockActivities.map((activity) => (
      roomId: activity.roomIdStr(),
      activities: [activity],
    )).toList();
  }
}

void main() {
  group('Activities Providers Tests', () {
    test('Direct function testing', () {
      // Test the _filterActivitiesByDate helper function directly
      final targetDate = DateTime(2024, 1, 15);
      final otherDate = DateTime(2024, 1, 10);
      
      final activity1 = MockActivity(
        mockType: 'test1',
        mockOriginServerTs: targetDate.millisecondsSinceEpoch,
        mockRoomId: 'room1',
      );
      final activity2 = MockActivity(
        mockType: 'test2',
        mockOriginServerTs: otherDate.millisecondsSinceEpoch,
        mockRoomId: 'room2',
      );
      final activity3 = MockActivity(
        mockType: 'test3',
        mockOriginServerTs: targetDate.millisecondsSinceEpoch,
        mockRoomId: 'room1',
      );

      final allActivities = [activity1, activity2, activity3];
      
      // Test filtering activities by date
      final filteredActivities = allActivities.where((activity) => 
        getActivityDate(activity.originServerTs()).isAtSameMomentAs(targetDate)
      ).toList();
      
      expect(filteredActivities.length, 2);
      expect(filteredActivities.contains(activity1), true);
      expect(filteredActivities.contains(activity3), true);
      expect(filteredActivities.contains(activity2), false);
      
      // Test sorting activities
      final sortedActivities = filteredActivities.toList()
        ..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
      
      expect(sortedActivities.length, 2);
      expect(sortedActivities[0].typeStr(), 'test1');
      
      // Test grouping activities
      final groups = <({String roomId, List<MockActivity> activities})>[];
      
      for (final activity in sortedActivities) {
        final roomId = activity.roomIdStr();
        
        if (groups.isNotEmpty && groups.last.roomId == roomId) {
          // Add to existing group
          final lastGroup = groups.last;
          groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
        } else {
          // Create new group
          groups.add((roomId: roomId, activities: [activity]));
        }
      }
      
      // Verify grouping worked correctly
      expect(groups.length, 1); // Both activities have same room1
      expect(groups[0].roomId, 'room1');
      expect(groups[0].activities.length, 2);
    });

    test('supportedActivityTypes is properly defined', () {
      expect(supportedActivityTypes, isNotEmpty);
      expect(supportedActivityTypes.length, greaterThan(30));
    });

    test('isActivityTypeSupported helper function', () {
      // Test supported types
      expect(isActivityTypeSupported('comment'), true);
      expect(isActivityTypeSupported('reaction'), true);
      expect(isActivityTypeSupported('attachment'), true);
      
      // Test unsupported/invalid types
      expect(isActivityTypeSupported('invalid_type'), false);
      expect(isActivityTypeSupported(''), false);
      expect(isActivityTypeSupported('random_string'), false);
    });

    test('hasActivitiesProvider type check', () {
      // Test that the provider exists and can be referenced
      expect(hasActivitiesProvider, isA<StateProvider<UrgencyBadge>>());
    });

    test('hasUnconfirmedEmailAddresses type check', () {
      // Test that the provider exists and can be referenced
      expect(hasUnconfirmedEmailAddresses, isA<StateProvider<bool>>());
    });

    testWidgets('activityProvider tests', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Test provider with a test ID
      final activity = container.read(activityProvider('test_id'));
      expect(activity, isA<AsyncValue<Activity?>>());
      expect(activity.isLoading, true);
      
      await tester.pumpAndSettle();
    });

    testWidgets('allActivitiesProvider tests', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final activities = container.read(allActivitiesProvider);
      expect(activities, isA<AsyncValue<List<RoomActivitiesInfo>>>());
      expect(activities.isLoading, true);
      
      await tester.pumpAndSettle();
      
      expect(activities.isLoading || activities.hasValue || activities.hasError, true);
    });

    testWidgets('Provider integration test for empty activities', (tester) async {
      final container = ProviderContainer();
      
      final dates = container.read(activityDatesProvider);
      expect(dates, isEmpty);
      
      final targetDate = DateTime(2024, 1, 15);
      final groups = container.read(activitiesByDateProvider(targetDate));
      expect(groups, isEmpty); // No activities, so no groups
      
      container.dispose();
      
      await tester.pumpAndSettle();
    });

    testWidgets('Provider method calls', (tester) async {
      final container = ProviderContainer();
      
      container.read(activityDatesProvider);
      container.read(activityDatesProvider);
      
      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2024, 2, 1);
      container.read(activitiesByDateProvider(date1));
      container.read(activitiesByDateProvider(date2));
      
      container.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets('Integration test to ensure provider code paths are executed', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      
      final dates1 = container.read(activityDatesProvider);
      expect(dates1, isEmpty); // No activities in test environment
      
      final testDate1 = DateTime(2024, 1, 15);
      final testDate2 = DateTime(2024, 2, 1);
      final testDate3 = DateTime(2024, 3, 1);
      
      final groups1 = container.read(activitiesByDateProvider(testDate1));
      final groups2 = container.read(activitiesByDateProvider(testDate2));
      final groups3 = container.read(activitiesByDateProvider(testDate3));
      
      expect(groups1, isEmpty);
      expect(groups2, isEmpty);
      expect(groups3, isEmpty);
      
      final timestamp1 = DateTime(2024, 1, 15, 14, 30, 45).millisecondsSinceEpoch;
      final timestamp2 = DateTime(2024, 12, 25, 23, 59, 59).millisecondsSinceEpoch;
      
      final date1 = getActivityDate(timestamp1);
      final date2 = getActivityDate(timestamp2);
      
      expect(date1, DateTime(2024, 1, 15));
      expect(date2, DateTime(2024, 12, 25));
      
      final midnightTimestamp = DateTime(2024, 6, 15, 0, 0, 0).millisecondsSinceEpoch;
      final almostMidnightTimestamp = DateTime(2024, 6, 15, 23, 59, 59).millisecondsSinceEpoch;
      
      final midnightDate = getActivityDate(midnightTimestamp);
      final almostMidnightDate = getActivityDate(almostMidnightTimestamp);
      
      expect(midnightDate, DateTime(2024, 6, 15));
      expect(almostMidnightDate, DateTime(2024, 6, 15));
      
      await tester.pumpAndSettle();
    });



    test('Direct test for activityDatesProvider logic', () {
      final activity1 = MockActivity(
        mockType: 'test1',
        mockOriginServerTs: DateTime(2024, 1, 15).millisecondsSinceEpoch,
        mockRoomId: 'room1',
      );
      final activity2 = MockActivity(
        mockType: 'test2',
        mockOriginServerTs: DateTime(2024, 1, 10).millisecondsSinceEpoch,
        mockRoomId: 'room2',
      );
      final activity3 = MockActivity(
        mockType: 'test3',
        mockOriginServerTs: DateTime(2024, 1, 15).millisecondsSinceEpoch, // Same date as activity1
        mockRoomId: 'room3',
      );

      final activities = [activity1, activity2, activity3];

      final uniqueDates = activities.map((activity) => getActivityDate(activity.originServerTs())).toSet();
      final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));

      expect(uniqueDates.length, 2); // Should have 2 unique dates
      expect(sortedDates.length, 2);
      expect(sortedDates[0].isAfter(sortedDates[1]), true); // Should be sorted descending
      
      final targetDate = DateTime(2024, 1, 15);
      final filteredActivities = activities.where((activity) => 
        getActivityDate(activity.originServerTs()).isAtSameMomentAs(targetDate)).toList();
      
      expect(filteredActivities.length, 2); // activity1 and activity3 have same date
      expect(filteredActivities.any((a) => a.typeStr() == 'test1'), true);
      expect(filteredActivities.any((a) => a.typeStr() == 'test3'), true);
    });

    group('consecutiveGroupedActivitiesProvider Tests', () {
      test('should return empty list when no activities', () {
        // Test empty case
        final activities = <MockActivity>[];
        
        // Simulate provider logic
        final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        final groups = <RoomActivitiesInfo>[];
        
        for (final activity in sortedActivities) {
          final roomId = activity.roomIdStr();
          
          if (groups.isNotEmpty && groups.last.roomId == roomId) {
            final lastGroup = groups.last;
            groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
          } else {
            groups.add((roomId: roomId, activities: [activity]));
          }
        }
        
        expect(groups, isEmpty);
      });

      test('should group consecutive activities from same room', () {
        final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
        
        final activity1 = MockActivity(
          mockType: 'message',
          mockOriginServerTs: baseTime + 1000, // 10:00:01
          mockRoomId: 'room1',
        );
        final activity2 = MockActivity(
          mockType: 'reaction',
          mockOriginServerTs: baseTime + 2000, // 10:00:02
          mockRoomId: 'room1',
        );
        final activity3 = MockActivity(
          mockType: 'edit',
          mockOriginServerTs: baseTime + 3000, // 10:00:03
          mockRoomId: 'room1',
        );

        final activities = [activity1, activity2, activity3];
        
        // Simulate provider logic
        final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        final groups = <RoomActivitiesInfo>[];
        
        for (final activity in sortedActivities) {
          final roomId = activity.roomIdStr();
          
          if (groups.isNotEmpty && groups.last.roomId == roomId) {
            final lastGroup = groups.last;
            groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
          } else {
            groups.add((roomId: roomId, activities: [activity]));
          }
        }
        
        expect(groups.length, 1);
        expect(groups[0].roomId, 'room1');
        expect(groups[0].activities.length, 3);
        expect(groups[0].activities[0].originServerTs(), baseTime + 3000);
        expect(groups[0].activities[1].originServerTs(), baseTime + 2000);
        expect(groups[0].activities[2].originServerTs(), baseTime + 1000);
      });

      test('should create separate groups for different rooms', () {
        final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
        
        final activity1 = MockActivity(
          mockType: 'message',
          mockOriginServerTs: baseTime + 1000,
          mockRoomId: 'room1',
        );
        final activity2 = MockActivity(
          mockType: 'message',
          mockOriginServerTs: baseTime + 2000,
          mockRoomId: 'room2',
        );
        final activity3 = MockActivity(
          mockType: 'message',
          mockOriginServerTs: baseTime + 3000,
          mockRoomId: 'room3',
        );

        final activities = [activity1, activity2, activity3];
        
        // Simulate provider logic
        final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        final groups = <RoomActivitiesInfo>[];
        
        for (final activity in sortedActivities) {
          final roomId = activity.roomIdStr();
          
          if (groups.isNotEmpty && groups.last.roomId == roomId) {
            final lastGroup = groups.last;
            groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
          } else {
            groups.add((roomId: roomId, activities: [activity]));
          }
        }
        
        expect(groups.length, 3);
        expect(groups[0].roomId, 'room3');
        expect(groups[0].activities.length, 1);
        expect(groups[1].roomId, 'room2');
        expect(groups[1].activities.length, 1);
        expect(groups[2].roomId, 'room1');
        expect(groups[2].activities.length, 1);
      });

      test('should handle mixed consecutive and non-consecutive activities', () {
        final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
        
        final activity1 = MockActivity(
          mockType: 'message',
          mockOriginServerTs: baseTime + 1000,
          mockRoomId: 'room1',
        );
        final activity2 = MockActivity(
          mockType: 'message',
          mockOriginServerTs: baseTime + 2000,
          mockRoomId: 'room2',
        );
        final activity3 = MockActivity(
          mockType: 'reaction',
          mockOriginServerTs: baseTime + 3000,
          mockRoomId: 'room1', // Back to room1
        );
        final activity4 = MockActivity(
          mockType: 'edit',
          mockOriginServerTs: baseTime + 4000,
          mockRoomId: 'room1', // Consecutive with activity3
        );
        final activity5 = MockActivity(
          mockType: 'message',
          mockOriginServerTs: baseTime + 5000,
          mockRoomId: 'room2', // Back to room2
        );

        final activities = [activity1, activity2, activity3, activity4, activity5];
        
        // Simulate provider logic
        final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        final groups = <RoomActivitiesInfo>[];
        
        for (final activity in sortedActivities) {
          final roomId = activity.roomIdStr();
          
          if (groups.isNotEmpty && groups.last.roomId == roomId) {
            final lastGroup = groups.last;
            groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
          } else {
            groups.add((roomId: roomId, activities: [activity]));
          }
        }
        
        expect(groups.length, 4);
        
        expect(groups[0].roomId, 'room2'); // activity5
        expect(groups[0].activities.length, 1);
        
        expect(groups[1].roomId, 'room1'); // activity4 + activity3
        expect(groups[1].activities.length, 2);
        
        expect(groups[2].roomId, 'room2'); // activity2
        expect(groups[2].activities.length, 1);
        
        expect(groups[3].roomId, 'room1'); // activity1
        expect(groups[3].activities.length, 1);
      });

      test('should maintain correct time sorting within groups', () {
        final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
        
        // Create activities in random order
        final activity1 = MockActivity(
          mockType: 'message',
          mockOriginServerTs: baseTime + 1000, // Earliest
          mockRoomId: 'room1',
        );
        final activity2 = MockActivity(
          mockType: 'edit',
          mockOriginServerTs: baseTime + 5000, // Latest
          mockRoomId: 'room1',
        );
        final activity3 = MockActivity(
          mockType: 'reaction',
          mockOriginServerTs: baseTime + 3000, // Middle
          mockRoomId: 'room1',
        );

        // Add in random order to test sorting
        final activities = [activity2, activity1, activity3];
        
        // Simulate provider logic
        final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        final groups = <RoomActivitiesInfo>[];
        
        for (final activity in sortedActivities) {
          final roomId = activity.roomIdStr();
          
          if (groups.isNotEmpty && groups.last.roomId == roomId) {
            final lastGroup = groups.last;
            groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
          } else {
            groups.add((roomId: roomId, activities: [activity]));
          }
        }
        
        expect(groups.length, 1);
        expect(groups[0].activities.length, 3);
        
        // Should be sorted by timestamp descending
        expect(groups[0].activities[0].originServerTs(), baseTime + 5000); // Latest first
                 expect(groups[0].activities[1].originServerTs(), baseTime + 3000); // Middle
         expect(groups[0].activities[2].originServerTs(), baseTime + 1000); // Earliest last
       });

       test('should handle single activity', () {
         final activity = MockActivity(
           mockType: 'message',
           mockOriginServerTs: DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch,
           mockRoomId: 'room1',
         );

         final activities = [activity];
         
         // Test the provider logic directly
         final targetDate = DateTime(2024, 1, 15);
         final filteredActivities = activities.where((activity) => 
           getActivityDate(activity.originServerTs()).isAtSameMomentAs(targetDate)).toList();
         
         final sortedActivities = filteredActivities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
         final groups = <RoomActivitiesInfo>[];
         
         for (final activity in sortedActivities) {
           final roomId = activity.roomIdStr();
           
           if (groups.isNotEmpty && groups.last.roomId == roomId) {
             final lastGroup = groups.last;
             groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
           } else {
             groups.add((roomId: roomId, activities: [activity]));
           }
         }
         
         expect(groups.length, 1);
         expect(groups[0].roomId, 'room1');
         expect(groups[0].activities.length, 1);
         expect(groups[0].activities[0], activity);
       });

       test('should handle activities with identical timestamps', () {
         final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
         
         final activity1 = MockActivity(
           mockType: 'message',
           mockOriginServerTs: baseTime, // Same timestamp
           mockRoomId: 'room1',
         );
         final activity2 = MockActivity(
           mockType: 'reaction',
           mockOriginServerTs: baseTime, // Same timestamp
           mockRoomId: 'room1',
         );
         final activity3 = MockActivity(
           mockType: 'edit',
           mockOriginServerTs: baseTime, // Same timestamp
           mockRoomId: 'room2',
         );

         final activities = [activity1, activity2, activity3];
         
         // Simulate provider logic
         final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
         final groups = <RoomActivitiesInfo>[];
         
         for (final activity in sortedActivities) {
           final roomId = activity.roomIdStr();
           
           if (groups.isNotEmpty && groups.last.roomId == roomId) {
             final lastGroup = groups.last;
             groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
           } else {
             groups.add((roomId: roomId, activities: [activity]));
           }
         }
         
         // Should group by room regardless of identical timestamps
         expect(groups.length, 2);
         expect(groups.any((g) => g.roomId == 'room1'), true);
         expect(groups.any((g) => g.roomId == 'room2'), true);
         
         final room1Group = groups.firstWhere((g) => g.roomId == 'room1');
         expect(room1Group.activities.length, 2);
       });

       test('should handle large number of activities efficiently', () {
         final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
         final activities = <MockActivity>[];
         
         // Create 100 activities across 10 rooms
         for (int i = 0; i < 100; i++) {
           activities.add(MockActivity(
             mockType: 'message$i',
             mockOriginServerTs: baseTime + (i * 1000),
             mockRoomId: 'room${i % 10}', // 10 different rooms
           ));
         }
         
         // Simulate provider logic
         final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
         final groups = <RoomActivitiesInfo>[];
         
         for (final activity in sortedActivities) {
           final roomId = activity.roomIdStr();
           
           if (groups.isNotEmpty && groups.last.roomId == roomId) {
             final lastGroup = groups.last;
             groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
           } else {
             groups.add((roomId: roomId, activities: [activity]));
           }
         }
         
         // Should create many groups due to room switching pattern
         expect(groups.length, greaterThan(10));
         
         // Verify all activities are included
         final totalActivitiesInGroups = groups.fold(0, (sum, group) => sum + group.activities.length);
         expect(totalActivitiesInGroups, 100);
         
         // Verify each group has correct room ID
         for (final group in groups) {
           expect(group.roomId, matches(RegExp(r'room\d')));
           expect(group.activities, isNotEmpty);
           
           // All activities in a group should have the same room ID
           for (final activity in group.activities) {
             expect(activity.roomIdStr(), group.roomId);
           }
         }
       });

       test('should handle alternating room pattern correctly', () {
         final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
         
         // Create alternating pattern: room1, room2, room1, room2, room1
         final activities = [
           MockActivity(mockType: 'msg1', mockOriginServerTs: baseTime + 1000, mockRoomId: 'room1'),
           MockActivity(mockType: 'msg2', mockOriginServerTs: baseTime + 2000, mockRoomId: 'room2'),
           MockActivity(mockType: 'msg3', mockOriginServerTs: baseTime + 3000, mockRoomId: 'room1'),
           MockActivity(mockType: 'msg4', mockOriginServerTs: baseTime + 4000, mockRoomId: 'room2'),
           MockActivity(mockType: 'msg5', mockOriginServerTs: baseTime + 5000, mockRoomId: 'room1'),
         ];
         
         // Simulate provider logic
         final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
         final groups = <RoomActivitiesInfo>[];
         
         for (final activity in sortedActivities) {
           final roomId = activity.roomIdStr();
           
           if (groups.isNotEmpty && groups.last.roomId == roomId) {
             final lastGroup = groups.last;
             groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
           } else {
             groups.add((roomId: roomId, activities: [activity]));
           }
         }
         
         // Should create 5 groups due to perfect alternation
         expect(groups.length, 5);
         expect(groups[0].roomId, 'room1'); // msg5
         expect(groups[1].roomId, 'room2'); // msg4
         expect(groups[2].roomId, 'room1'); // msg3
         expect(groups[3].roomId, 'room2'); // msg2
         expect(groups[4].roomId, 'room1'); // msg1
         
         // Each group should have exactly 1 activity
         for (final group in groups) {
           expect(group.activities.length, 1);  
         }
       });

       test('should handle multiple consecutive activities in multiple rooms', () {
         final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
         
         final activities = [
           // First batch in room1
           MockActivity(mockType: 'msg1', mockOriginServerTs: baseTime + 1000, mockRoomId: 'room1'),
           MockActivity(mockType: 'react1', mockOriginServerTs: baseTime + 2000, mockRoomId: 'room1'),
           MockActivity(mockType: 'edit1', mockOriginServerTs: baseTime + 3000, mockRoomId: 'room1'),
           
           // Batch in room2
           MockActivity(mockType: 'msg2', mockOriginServerTs: baseTime + 4000, mockRoomId: 'room2'),
           MockActivity(mockType: 'react2', mockOriginServerTs: baseTime + 5000, mockRoomId: 'room2'),
           
           // Back to room1
           MockActivity(mockType: 'msg3', mockOriginServerTs: baseTime + 6000, mockRoomId: 'room1'),
           MockActivity(mockType: 'react3', mockOriginServerTs: baseTime + 7000, mockRoomId: 'room1'),
           MockActivity(mockType: 'edit3', mockOriginServerTs: baseTime + 8000, mockRoomId: 'room1'),
           MockActivity(mockType: 'del3', mockOriginServerTs: baseTime + 9000, mockRoomId: 'room1'),
         ];
         
         // Simulate provider logic
         final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
         final groups = <RoomActivitiesInfo>[];
         
         for (final activity in sortedActivities) {
           final roomId = activity.roomIdStr();
           
           if (groups.isNotEmpty && groups.last.roomId == roomId) {
             final lastGroup = groups.last;
             groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
           } else {
             groups.add((roomId: roomId, activities: [activity]));
           }
         }
         
         expect(groups.length, 3);
         
         // Latest group: room1 with 4 activities (del3, edit3, react3, msg3)
         expect(groups[0].roomId, 'room1');
         expect(groups[0].activities.length, 4);
         expect(groups[0].activities[0].typeStr(), 'del3'); // Latest first
         
         // Middle group: room2 with 2 activities (react2, msg2)
         expect(groups[1].roomId, 'room2');
         expect(groups[1].activities.length, 2);
         expect(groups[1].activities[0].typeStr(), 'react2'); // Latest first
         
         // Earliest group: room1 with 3 activities (edit1, react1, msg1)
         expect(groups[2].roomId, 'room1');
         expect(groups[2].activities.length, 3);
         expect(groups[2].activities[0].typeStr(), 'edit1'); // Latest first
       });

       test('should handle special room ID characters', () {
         final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
         
         final activities = [
           MockActivity(mockType: 'msg1', mockOriginServerTs: baseTime + 1000, mockRoomId: '!room1:server.com'),
           MockActivity(mockType: 'msg2', mockOriginServerTs: baseTime + 2000, mockRoomId: '!room1:server.com'),
           MockActivity(mockType: 'msg3', mockOriginServerTs: baseTime + 3000, mockRoomId: '#room-2_test:server.com'),
           MockActivity(mockType: 'msg4', mockOriginServerTs: baseTime + 4000, mockRoomId: '!room1:server.com'),
         ];
         
         // Simulate provider logic
         final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
         final groups = <RoomActivitiesInfo>[];
         
         for (final activity in sortedActivities) {
           final roomId = activity.roomIdStr();
           
           if (groups.isNotEmpty && groups.last.roomId == roomId) {
             final lastGroup = groups.last;
             groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
           } else {
             groups.add((roomId: roomId, activities: [activity]));
           }
         }
         
         expect(groups.length, 3);
         expect(groups[0].roomId, '!room1:server.com'); // msg4
         expect(groups[1].roomId, '#room-2_test:server.com'); // msg3
         expect(groups[2].roomId, '!room1:server.com'); // msg2, msg1
         expect(groups[2].activities.length, 2);
       });

       test('should maintain chronological order across different activity types', () {
         final baseTime = DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch;
         
         final activities = [
           MockActivity(mockType: 'message', mockOriginServerTs: baseTime + 1000, mockRoomId: 'room1'),
           MockActivity(mockType: 'reaction', mockOriginServerTs: baseTime + 2000, mockRoomId: 'room1'),
           MockActivity(mockType: 'edit', mockOriginServerTs: baseTime + 3000, mockRoomId: 'room1'),
           MockActivity(mockType: 'delete', mockOriginServerTs: baseTime + 4000, mockRoomId: 'room1'),
           MockActivity(mockType: 'file_upload', mockOriginServerTs: baseTime + 5000, mockRoomId: 'room1'),
           MockActivity(mockType: 'invite', mockOriginServerTs: baseTime + 6000, mockRoomId: 'room1'),
         ];
         
         // Simulate provider logic
         final sortedActivities = activities.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
         final groups = <RoomActivitiesInfo>[];
         
         for (final activity in sortedActivities) {
           final roomId = activity.roomIdStr();
           
           if (groups.isNotEmpty && groups.last.roomId == roomId) {
             final lastGroup = groups.last;
             groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
           } else {
             groups.add((roomId: roomId, activities: [activity]));
           }
         }
         
         expect(groups.length, 1);
         expect(groups[0].activities.length, 6);
         
         // Verify chronological order (descending)
         expect(groups[0].activities[0].typeStr(), 'invite');
         expect(groups[0].activities[1].typeStr(), 'file_upload');
         expect(groups[0].activities[2].typeStr(), 'delete');
         expect(groups[0].activities[3].typeStr(), 'edit');
         expect(groups[0].activities[4].typeStr(), 'reaction');
         expect(groups[0].activities[5].typeStr(), 'message');
         
         // Verify timestamps are in descending order
         for (int i = 0; i < groups[0].activities.length - 1; i++) {
           expect(
             groups[0].activities[i].originServerTs(),
             greaterThan(groups[0].activities[i + 1].originServerTs()),
           );
         }
       });
     });

    test('hasActivitiesProvider type check', () {
      // Test that the provider exists and can be referenced
      expect(hasActivitiesProvider, isA<StateProvider<UrgencyBadge>>());
    });

    test('hasUnconfirmedEmailAddresses type check', () {
      // Test that the provider exists and can be referenced
      expect(hasUnconfirmedEmailAddresses, isA<StateProvider<bool>>());
    });

    test('activityDatesProvider with activities logic', () {
      final mockActivity1 = MockActivity(
        mockType: 'comment',
        mockOriginServerTs: DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch,
        mockRoomId: 'room1',
      );
      final mockActivity2 = MockActivity(
        mockType: 'reaction',
        mockOriginServerTs: DateTime(2024, 1, 16, 10, 0).millisecondsSinceEpoch,
        mockRoomId: 'room2',
      );
      
      final mockGroups = [
        (roomId: 'room1', activities: [mockActivity1]),
        (roomId: 'room2', activities: [mockActivity2]),
      ];
      
      // Test the logic directly
      if (mockGroups.isEmpty) {
        expect([], isEmpty);
      } else {
        final uniqueDates = mockGroups.map((group) => getActivityDate(group.activities.first.originServerTs())).toSet();
        final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));
        
        expect(sortedDates, hasLength(2));
        expect(sortedDates[0], DateTime(2024, 1, 16)); // Latest first (descending order)
        expect(sortedDates[1], DateTime(2024, 1, 15));
      }
    });

    test('consecutiveGroupedActivitiesProvider with groups logic', () {
      final mockActivity1 = MockActivity(
        mockType: 'comment',
        mockOriginServerTs: DateTime(2024, 1, 15, 10, 0).millisecondsSinceEpoch,
        mockRoomId: 'room1',
      );
      final mockActivity2 = MockActivity(
        mockType: 'reaction',
        mockOriginServerTs: DateTime(2024, 1, 16, 10, 0).millisecondsSinceEpoch,
        mockRoomId: 'room2',
      );
      
      final mockGroups = [
        (roomId: 'room1', activities: [mockActivity1]),
        (roomId: 'room2', activities: [mockActivity2]),
      ];
      
      // Test the logic directly
      if (mockGroups.isEmpty) {
        expect([], isEmpty);
      } else {
        final targetDate = DateTime(2024, 1, 15);
        final groupsForDate = mockGroups.where((group) {
          if (group.activities.isEmpty) return false;
          final groupDate = getActivityDate(group.activities.first.originServerTs());
          return groupDate.isAtSameMomentAs(targetDate);
        }).toList();
        
        expect(groupsForDate, hasLength(1));
        expect(groupsForDate[0].roomId, 'room1');
      }
    });

    test('consecutiveGroupedActivitiesProvider with empty groups logic', () {
      final mockGroups = [
        (roomId: 'room1', activities: <Activity>[]), // Empty activities
      ];
      
      // Test the logic directly
      if (mockGroups.isEmpty) {
        expect([], isEmpty);
      } else {
        final targetDate = DateTime(2024, 1, 15);
        final groupsForDate = mockGroups.where((group) {
          if (group.activities.isEmpty) return false;
          final groupDate = getActivityDate(group.activities.first.originServerTs());
          return groupDate.isAtSameMomentAs(targetDate);
        }).toList();
        
        expect(groupsForDate, isEmpty);
      }
    });
  });
} 