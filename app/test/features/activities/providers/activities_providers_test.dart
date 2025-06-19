import 'package:acter/common/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../activity/mock_data/mock_activity.dart';

void main() {
  group('Activities Providers Tests', () {
    late List<MockActivity> mockActivities;

    setUp(() {
      // Create mock activities with different dates and room IDs
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      mockActivities = [
        // Today's activities
        MockActivity(
          mockType: 'comment',
          mockRoomId: 'room1',
          mockOriginServerTs: today.millisecondsSinceEpoch + 1000, // 1 second after midnight
        ),
        MockActivity(
          mockType: 'reaction',
          mockRoomId: 'room1',
          mockOriginServerTs: today.millisecondsSinceEpoch + 2000, // 2 seconds after midnight
        ),
        MockActivity(
          mockType: 'attachment',
          mockRoomId: 'room2',
          mockOriginServerTs: today.millisecondsSinceEpoch + 3000, // 3 seconds after midnight
        ),
        // Yesterday's activities
        MockActivity(
          mockType: 'taskAdd',
          mockRoomId: 'room1',
          mockOriginServerTs: yesterday.millisecondsSinceEpoch + 1000,
        ),
        MockActivity(
          mockType: 'taskComplete',
          mockRoomId: 'room3',
          mockOriginServerTs: yesterday.millisecondsSinceEpoch + 2000,
        ),
        // Two days ago activities
        MockActivity(
          mockType: 'roomName',
          mockRoomId: 'room2',
          mockOriginServerTs: twoDaysAgo.millisecondsSinceEpoch + 1000,
        ),
      ];
    });

    group('Helper Functions', () {
      test('getActivityDate should return date without time component', () {
        final activity = mockActivities[0];
        final activityDate = getActivityDate(activity);
        
        expect(activityDate.hour, equals(0));
        expect(activityDate.minute, equals(0));
        expect(activityDate.second, equals(0));
        expect(activityDate.millisecond, equals(0));
      });

      test('getActivityDate should handle different timestamps correctly', () {
        final activity1 = mockActivities[0]; // Today
        final activity2 = mockActivities[3]; // Yesterday
        
        final date1 = getActivityDate(activity1);
        final date2 = getActivityDate(activity2);
        
        expect(date1.isAfter(date2), isTrue);
        expect(date1.difference(date2).inDays, equals(1));
      });
    });

    group('Date Filtering Logic', () {
      test('should filter activities by date correctly', () {
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final yesterday = today.subtract(const Duration(days: 1));
        
        final todayActivities = mockActivities.where((activity) {
          final activityDate = getActivityDate(activity);
          return activityDate.isAtSameMomentAs(today);
        }).toList();
        
        final yesterdayActivities = mockActivities.where((activity) {
          final activityDate = getActivityDate(activity);
          return activityDate.isAtSameMomentAs(yesterday);
        }).toList();
        
        expect(todayActivities, hasLength(3));
        expect(yesterdayActivities, hasLength(2));
      });

      test('should handle empty activity list', () {
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final emptyActivities = <MockActivity>[];
        
        final filtered = emptyActivities.where((activity) {
          final activityDate = getActivityDate(activity);
          return activityDate.isAtSameMomentAs(today);
        }).toList();
        
        expect(filtered, isEmpty);
      });

      test('should return unique dates sorted in descending order', () {
        final uniqueDates = mockActivities.map(getActivityDate).toSet();
        final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));
        
        expect(sortedDates, hasLength(3));
        expect(sortedDates[0].isAfter(sortedDates[1]), isTrue);
        expect(sortedDates[1].isAfter(sortedDates[2]), isTrue);
      });

      test('should return dates without time component', () {
        final uniqueDates = mockActivities.map(getActivityDate).toSet();
        
        for (final date in uniqueDates) {
          expect(date.hour, equals(0));
          expect(date.minute, equals(0));
          expect(date.second, equals(0));
          expect(date.millisecond, equals(0));
        }
      });
    });

    group('Consecutive Grouping Logic', () {
      test('should group consecutive activities by room ID', () {
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final todayActivities = mockActivities.where((activity) {
          final activityDate = getActivityDate(activity);
          return activityDate.isAtSameMomentAs(today);
        }).toList();
        
        // Sort by time descending
        todayActivities.sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        
        // Group consecutive activities by roomId
        final groups = <({String roomId, List<MockActivity> activities})>[];
        
        for (final activity in todayActivities) {
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
        
        expect(groups, hasLength(2)); // 2 different rooms
        
        // After sorting by timestamp descending, room2 (3000ms) should come first, then room1 (2000ms, 1000ms)
        expect(groups[0].roomId, equals('room2'));
        expect(groups[0].activities, hasLength(1));
        
        expect(groups[1].roomId, equals('room1'));
        expect(groups[1].activities, hasLength(2));
      });

      test('should sort activities by timestamp descending within groups', () {
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final todayActivities = mockActivities.where((activity) {
          final activityDate = getActivityDate(activity);
          return activityDate.isAtSameMomentAs(today);
        }).toList();
        
        // Sort by time descending
        todayActivities.sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        
        // Group consecutive activities by roomId
        final groups = <({String roomId, List<MockActivity> activities})>[];
        
        for (final activity in todayActivities) {
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
        
        // Check that activities in room1 group are sorted by timestamp descending
        final room1Group = groups.firstWhere((group) => group.roomId == 'room1');
        final room1Activities = room1Group.activities;
        expect(room1Activities, hasLength(2));
        expect(room1Activities[0].originServerTs() > room1Activities[1].originServerTs(), isTrue);
      });

      test('should handle single activity correctly', () {
        final singleActivity = [mockActivities[0]];
        
        // Sort by time descending
        singleActivity.sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        
        // Group consecutive activities by roomId
        final groups = <({String roomId, List<MockActivity> activities})>[];
        
        for (final activity in singleActivity) {
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
        
        expect(groups, hasLength(1));
        expect(groups[0].roomId, equals('room1'));
        expect(groups[0].activities, hasLength(1));
      });

      test('should handle activities from different rooms correctly', () {
        final mixedActivities = [
          MockActivity(mockType: 'comment', mockRoomId: 'roomA', mockOriginServerTs: 1000),
          MockActivity(mockType: 'reaction', mockRoomId: 'roomB', mockOriginServerTs: 2000),
          MockActivity(mockType: 'attachment', mockRoomId: 'roomA', mockOriginServerTs: 3000),
          MockActivity(mockType: 'taskAdd', mockRoomId: 'roomC', mockOriginServerTs: 4000),
        ];
        
        // Sort by time descending
        mixedActivities.sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        
        // Group consecutive activities by roomId
        final groups = <({String roomId, List<MockActivity> activities})>[];
        
        for (final activity in mixedActivities) {
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
        
        expect(groups, hasLength(4)); // Each room gets its own group due to sorting
        
        // After sorting by timestamp descending: roomC(4000), roomA(3000), roomB(2000), roomA(1000)
        expect(groups[0].roomId, equals('roomC'));
        expect(groups[1].roomId, equals('roomA'));
        expect(groups[2].roomId, equals('roomB'));
        expect(groups[3].roomId, equals('roomA'));
      });

      test('should handle empty activity list for grouping', () {
        final emptyActivities = <MockActivity>[];
        
        // Sort by time descending
        emptyActivities.sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));
        
        // Group consecutive activities by roomId
        final groups = <({String roomId, List<MockActivity> activities})>[];
        
        for (final activity in emptyActivities) {
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
        
        expect(groups, isEmpty);
      });
    });
  });
} 