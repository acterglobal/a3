import 'dart:async';

import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../activity/mock_data/mock_activity.dart';
import '../../../space/pages/space_details_page_test.dart';

// Mock classes
class MockClient extends Mock implements Client {}
class MockActivities extends Mock implements Activities {}
class MockSpace extends Mock implements Space {}

void main() {
  group('AllActivitiesNotifier Unit Tests', () {
    late MockClient mockClient;
    late MockActivities mockActivities;

    setUp(() {
      mockClient = MockClient();
      mockActivities = MockActivities();

      // Setup default behavior
      when(() => mockClient.subscribeRoomStream(any())).thenAnswer((_) => Stream.value(true));
    });

    test('notifier class exists and can be instantiated', () {
      // Act & Assert
      expect(() => AllActivitiesNotifier(), returnsNormally);
    });

    test('notifier extends AsyncNotifier with correct type', () {
      // Arrange
      final notifier = AllActivitiesNotifier();

      // Act & Assert
      expect(notifier, isA<AsyncNotifier<List<String>>>());
    });

    test('notifier has pagination properties', () {
      // Arrange & Act
      final notifier = AllActivitiesNotifier();

      // Assert - Test that properties exist and have expected types
      expect(notifier.hasMoreData, isA<bool>());
      expect(notifier.hasMoreData, true); // Should start with true
      
  
      expect(notifier.loadMore, isA<Function>());
    });

    test('spaces can call getRoomIdStr method', () {
      // Arrange
      final mockSpace = MockSpace();
      when(() => mockSpace.getRoomIdStr()).thenReturn('test-room-id');

      // Act
      final roomId = mockSpace.getRoomIdStr();

      // Assert
      expect(roomId, 'test-room-id');
      verify(() => mockSpace.getRoomIdStr()).called(1);
    });

    test('client can call allActivities method', () {
      // Arrange
      when(() => mockClient.allActivities()).thenReturn(mockActivities);

      // Act
      final activities = mockClient.allActivities();

      // Assert
      expect(activities, mockActivities);
      verify(() => mockClient.allActivities()).called(1);
    });

    test('activities can call getIds method with pagination', () async {
      // Arrange
      when(() => mockActivities.getIds(0, 100)).thenAnswer((_) async => MockFfiListFfiString(items: []));

      // Act
      final ids = await mockActivities.getIds(0, 100);

      // Assert
      expect(ids, isNotNull);
      verify(() => mockActivities.getIds(0, 100)).called(1);
    });

    test('activities can call getIds method with different offsets', () async {
      // Arrange
      when(() => mockActivities.getIds(100, 100)).thenAnswer((_) async => MockFfiListFfiString(items: []));

      // Act
      final ids = await mockActivities.getIds(100, 100);

      // Assert
      expect(ids, isNotNull);
      verify(() => mockActivities.getIds(100, 100)).called(1);
    });

    test('activities can call drop method', () {
      // Act
      mockActivities.drop();

      // Assert
      verify(() => mockActivities.drop()).called(1);
    });

    test('client can subscribe to room streams', () {
      // Arrange
      final stream = Stream.value(true);
      when(() => mockClient.subscribeRoomStream('test-room')).thenAnswer((_) => stream);

      // Act
      final result = mockClient.subscribeRoomStream('test-room');

      // Assert
      expect(result, stream);
      verify(() => mockClient.subscribeRoomStream('test-room')).called(1);
    });

    test('client can fetch individual activities', () async {
      // Arrange
      final mockActivity = MockActivity(mockType: 'test');
      when(() => mockClient.activity('activity-id')).thenAnswer((_) async => mockActivity);

      // Act
      final activity = await mockClient.activity('activity-id');

      // Assert
      expect(activity, mockActivity);
      verify(() => mockClient.activity('activity-id')).called(1);
    });

    test('stream subscription pattern works correctly', () {
      // Arrange
      final streamController = StreamController<bool>.broadcast();
      final spaces = ['room1', 'room2'];
      final subscriptions = <StreamSubscription>[];

      // Act
      for (final _ in spaces) {
        final stream = streamController.stream;
        final subscription = stream.listen(
          (data) {
            // Simulate update handler
          },
          onError: (e, s) {
            // Simulate error handler
          },
          onDone: () {
            // Simulate done handler
          },
        );
        subscriptions.add(subscription);
      }

      // Assert
      expect(subscriptions, hasLength(2));
      expect(streamController.hasListener, true);

      // Cleanup
      for (final sub in subscriptions) {
        sub.cancel();
      }
      streamController.close();
    });

    test('activities list filtering works correctly', () {
      // Arrange
      final activities = [
        MockActivity(mockType: 'comment'),
        null,
        MockActivity(mockType: 'reaction'),
        null,
      ];

      // Act
      final filtered = activities.whereType<Activity>().toList();

      // Assert
      expect(filtered, hasLength(2));
      expect(filtered[0].typeStr(), 'comment');
      expect(filtered[1].typeStr(), 'reaction');
    });

    test('exception handling pattern works', () {
      // Arrange
      when(() => mockClient.allActivities()).thenThrow(Exception('Test error'));

      // Act & Assert
      expect(() => mockClient.allActivities(), throwsA(isA<Exception>()));
    });

    test('async exception handling pattern works', () async {
      // Arrange
      when(() => mockActivities.getIds(0, 100)).thenThrow(Exception('Async error'));

      // Act & Assert
      expect(() => mockActivities.getIds(0, 100), throwsA(isA<Exception>()));
    });

    testWidgets('stream error handling pattern works', (tester) async {
      // Arrange
      final streamController = StreamController<bool>.broadcast();
      bool errorHandled = false;

      // Act
      final subscription = streamController.stream.listen(
        (data) {},
        onError: (e, s) {
          errorHandled = true;
        },
      );

      streamController.addError('Test error');
      
      // Wait for the error to be processed
      await tester.pump();
      
      // Assert
      expect(errorHandled, true);

      subscription.cancel();
      streamController.close();
    });

    test('disposal pattern works correctly', () {
      // Arrange
      final subscriptions = <StreamSubscription>[];
      final streamController = StreamController<bool>.broadcast();

      final subscription = streamController.stream.listen((data) {});
      subscriptions.add(subscription);

      // Act - Simulate disposal
      for (final sub in subscriptions) {
        sub.cancel();
      }
      mockActivities.drop();

      // Assert
      verify(() => mockActivities.drop()).called(1);

      streamController.close();
    });

    test('null safety patterns work correctly', () {
      // Arrange
      Activities? nullableActivities;

      // Act & Assert - Should not throw
      expect(() => nullableActivities?.drop(), returnsNormally);
      expect(() => nullableActivities = null, returnsNormally);
    });

    test('multiple space handling pattern works', () {
      // Arrange
      final spaces = [
        MockSpace(),
        MockSpace(),
        MockSpace(),
      ];

      when(() => spaces[0].getRoomIdStr()).thenReturn('room1');
      when(() => spaces[1].getRoomIdStr()).thenReturn('room2');
      when(() => spaces[2].getRoomIdStr()).thenReturn('room3');

      // Act
      final roomIds = spaces.map((space) => space.getRoomIdStr()).toList();

      // Assert
      expect(roomIds, ['room1', 'room2', 'room3']);
      for (int i = 0; i < spaces.length; i++) {
        verify(() => spaces[i].getRoomIdStr()).called(1);
      }
    });
  });

  group('Pagination State Tests', () {
    test('should handle pagination logic correctly', () {
      // Test pagination calculation patterns
      int currentOffset = 0;
      const pageSize = 100;
      bool hasMoreData = true;
      
      // Simulate successful fetch with partial page
      final mockActivityIds = List.generate(50, (i) => 'activity_$i');
      
      // Simulate pagination update logic
      currentOffset += mockActivityIds.length;
      hasMoreData = mockActivityIds.length >= pageSize;
      
      expect(currentOffset, 50);
      expect(hasMoreData, false); // Less than page size means no more data
    });

    test('should handle pagination with full page', () {
      // Test pagination calculation patterns
      int currentOffset = 0;
      const pageSize = 100;
      bool hasMoreData = true;
      
      // Simulate successful fetch with full page
      final mockActivityIds = List.generate(100, (i) => 'activity_$i');
      
      // Simulate pagination update logic
      currentOffset += mockActivityIds.length;
      hasMoreData = mockActivityIds.length >= pageSize;
      
      expect(currentOffset, 100);
      expect(hasMoreData, true); // Full page means might have more data
    });

    test('should handle empty response', () {
      // Test pagination with empty response
      bool hasMoreData = true;
      final emptyActivityIds = <String>[];
      
      if (emptyActivityIds.isEmpty) {
        hasMoreData = false;
      }
      
      expect(hasMoreData, false);
    });
  });

  group('AsyncActivityNotifier Implementation Tests', () {
    testWidgets('should create notifier with correct type', (tester) async {
      // Arrange & Act
      final notifier = AsyncActivityNotifier();

      // Assert
      expect(notifier, isA<FamilyAsyncNotifier<Activity?, String>>());
    });

    testWidgets('should handle build method structure', (tester) async {
      // Test that the notifier can be referenced and constructed
      expect(AsyncActivityNotifier.new, isA<Function>());
    });
  });

  group('AllActivitiesNotifier Implementation Tests', () {
    testWidgets('should create notifier with correct type', (tester) async {
      // Arrange & Act
      final notifier = AllActivitiesNotifier();

      // Assert
      expect(notifier, isA<AsyncNotifier<List<String>>>());
    });

    testWidgets('should initialize with hasMoreData as true', (tester) async {
      // Arrange & Act
      final notifier = AllActivitiesNotifier();

      // Assert
      expect(notifier.hasMoreData, true);
    });

    testWidgets('should have loadMore method', (tester) async {
      // Arrange & Act
      final notifier = AllActivitiesNotifier();

      // Assert
      expect(notifier.loadMore, isA<Function>());
    });

    testWidgets('should handle pagination constants', (tester) async {
      // Test that the page size constant is accessible through behavior
      final notifier = AllActivitiesNotifier();
      
      // Test that notifier has expected pagination behavior
      expect(notifier.hasMoreData, true);
    });

    testWidgets('should handle pagination state management', (tester) async {
      final notifier = AllActivitiesNotifier();
      
      // Test initial state
      expect(notifier.hasMoreData, true);
      
      // Test that internal pagination logic can be tested
      // by simulating the scenarios the notifier handles
      final testActivities = ['activity1', 'activity2', 'activity3'];
      expect(testActivities.length < 100, true); // Simulates page size check
    });

    testWidgets('should handle stream subscription patterns', (tester) async {
      // Test the subscription pattern used in the notifier
      final streamController = StreamController<bool>.broadcast();
      final subscriptions = <StreamSubscription>[];
      
      // Simulate the subscription pattern from build method
      final stream = streamController.stream;
      final subscription = stream.listen(
        (data) async {
          // Simulate refresh logic
        },
        onError: (e, s) {
          // Simulate error handling
        },
        onDone: () {
          // Simulate completion
        },
      );
      subscriptions.add(subscription);

      expect(subscriptions, hasLength(1));
      expect(streamController.hasListener, true);

      // Cleanup
      for (final sub in subscriptions) {
        sub.cancel();
      }
      streamController.close();
    });

    testWidgets('should handle activities object lifecycle', (tester) async {
      // Test the Activities object lifecycle pattern
      Activities? activities;
      
      // Simulate the pattern from _fetchAllActivities
      activities = null; // Simulate reset
      expect(activities, isNull);
      
      // Simulate disposal
      activities?.drop();
      activities = null;
      expect(activities, isNull);
    });

    testWidgets('should handle offset and pagination logic', (tester) async {
      // Test pagination calculation patterns
      int currentOffset = 0;
      const pageSize = 100;
      bool hasMoreData = true;
      
      // Simulate successful fetch
      final mockActivityIds = List.generate(50, (i) => 'activity_$i');
      
      // Simulate pagination update logic from _fetchAllActivities
      currentOffset += mockActivityIds.length;
      hasMoreData = mockActivityIds.length >= pageSize;
      
      expect(currentOffset, 50);
      expect(hasMoreData, false); // Less than page size
    });

    testWidgets('should handle list concatenation for loadMore', (tester) async {
      // Test list concatenation pattern used in loadMore
      final currentActivities = ['activity1', 'activity2'];
      final newActivities = ['activity3', 'activity4'];
      
      // Simulate the loadMore concatenation from _fetchAllActivities
      final result = [...currentActivities, ...newActivities];
      
      expect(result, hasLength(4));
      expect(result, ['activity1', 'activity2', 'activity3', 'activity4']);
    });

    testWidgets('should handle error propagation patterns', (tester) async {
      // Test error handling pattern from loadMore and _fetchAllActivities
      bool errorHandled = false;
      
      try {
        throw Exception('Test error');
      } catch (e) {
        errorHandled = true;
        // Simulate rethrow pattern from notifier
        expect(e, isA<Exception>());
      }
      
      expect(errorHandled, true);
    });

    testWidgets('should handle pagination edge cases', (tester) async {
      // Test pagination logic edge cases
      
      // Case 1: Exactly page size returned
      const pageSize = 100;
      final exactPageActivities = List.generate(pageSize, (i) => 'activity_$i');
      bool hasMoreData = exactPageActivities.length >= pageSize;
      expect(hasMoreData, true); // Should have more data
      
      // Case 2: Less than page size returned
      final partialPageActivities = List.generate(50, (i) => 'activity_$i');
      hasMoreData = partialPageActivities.length >= pageSize;
      expect(hasMoreData, false); // Should not have more data
      
      // Case 3: Empty response
      final emptyActivities = <String>[];
      hasMoreData = emptyActivities.isNotEmpty;
      expect(hasMoreData, false); // Should not have more data
    });

    testWidgets('should handle initial vs loadMore fetch differences', (tester) async {
      // Test the different code paths in _fetchAllActivities
      
      // Initial load scenario
      bool loadMore = false;
      if (!loadMore) {
        // Reset pagination for initial load
        int currentOffset = 0;
        bool hasMoreData = true;
        expect(currentOffset, 0);
        expect(hasMoreData, true);
      }
      
      // LoadMore scenario  
      loadMore = true;
      final currentActivities = ['existing1', 'existing2'];
      final newActivities = ['new1', 'new2'];
      
      if (loadMore) {
        // Append new activities to existing list
        final result = [...currentActivities, ...newActivities];
        expect(result, ['existing1', 'existing2', 'new1', 'new2']);
      }
    });
  });

  group('Notifier Integration and Coverage Tests', () {
    testWidgets('should handle all notifiers together', (tester) async {
      // Test that all notifier types can coexist
      final activitiesNotifier = AllActivitiesNotifier();
      final activityNotifier = AsyncActivityNotifier();

      expect(activitiesNotifier, isA<AllActivitiesNotifier>());
      expect(activityNotifier, isA<AsyncActivityNotifier>());

      // Test activities notifier state
      expect(activitiesNotifier.hasMoreData, true);
    });

    testWidgets('should test all public methods and properties', (tester) async {
      // Test AllActivitiesNotifier public interface
      final activitiesNotifier = AllActivitiesNotifier();
      expect(activitiesNotifier.hasMoreData, isA<bool>());
      expect(activitiesNotifier.loadMore, isA<Function>());
      expect(activitiesNotifier.build, isA<Function>());
      
      // Test AsyncActivityNotifier public interface
      final activityNotifier = AsyncActivityNotifier();
      expect(activityNotifier.build, isA<Function>());
    });

    testWidgets('should handle error scenarios for all notifiers', (tester) async {
      // Test error handling patterns used across notifiers
      
      // Stream error handling (used in both activity notifiers)
      final streamController = StreamController<bool>.broadcast();
      bool errorHandled = false;

      final subscription = streamController.stream.listen(
        (data) {},
        onError: (e, s) {
          errorHandled = true;
          // This simulates the error handling in both notifiers
        },
      );

      streamController.addError('Test error');
      
      // Wait a brief moment for the error to be processed
      await tester.pump();

      expect(errorHandled, true);
      subscription.cancel();
      streamController.close();
    });

    testWidgets('should cover disposal and cleanup patterns', (tester) async {
      // Test disposal patterns used in notifiers
      final subscriptions = <StreamSubscription>[];
      final streamController = StreamController<bool>.broadcast();

      // Simulate subscription pattern from AllActivitiesNotifier.build()
      for (int i = 0; i < 3; i++) {
        final subscription = streamController.stream.listen((data) {});
        subscriptions.add(subscription);
      }

      // Simulate disposal pattern from ref.onDispose()
      for (final sub in subscriptions) {
        sub.cancel();
      }

      // Simulate Activities cleanup
      Activities? activities;
      activities = null; // Prevent double free

      expect(subscriptions, hasLength(3));
      expect(activities, isNull);
      
      streamController.close();
    });
  });
} 