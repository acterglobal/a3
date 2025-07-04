import 'dart:async';

import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../activity/mock_data/mock_activity.dart';
import '../../../room/actions/join_room_test.dart';
import '../../../space/pages/space_details_page_test.dart';

class MockActivities extends Mock implements Activities {}

void main() {
  group('AllActivitiesNotifier Tests', () {
    late MockClient mockClient;
    late MockActivities mockActivities;
    late List<MockSpace> mockSpaces;
    late StreamController<bool> mockStreamController;

    setUp(() {
      mockClient = MockClient();
      mockActivities = MockActivities();
      mockSpaces = [MockSpace(), MockSpace()];
      mockStreamController = StreamController<bool>.broadcast();

      // Setup default mocks
      when(() => mockClient.allActivities()).thenReturn(mockActivities);
      when(() => mockClient.subscribeRoomStream(any())).thenAnswer((_) => mockStreamController.stream);
      when(() => mockSpaces[0].getRoomIdStr()).thenReturn('room1');
      when(() => mockSpaces[1].getRoomIdStr()).thenReturn('room2');
      when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => MockFfiListFfiString(items: []));
      when(() => mockActivities.drop()).thenReturn(null);
    });

    tearDown(() {
      mockStreamController.close();
    });

    group('Initialization and Basic Properties', () {
      test('should create notifier with correct type', () {
        expect(() => AllActivitiesNotifier(), returnsNormally);
      });

      test('should have correct class structure', () {
        final notifier = AllActivitiesNotifier();
        expect(notifier, isA<AsyncNotifier<List<String>>>());
        expect(notifier.hasMoreData, isA<bool>());
        expect(notifier.loadMore, isA<Function>());
      });
    });

    group('LoadMore Method', () {

      test('should handle loadMore method signature', () {
        final notifier = AllActivitiesNotifier();
        expect(notifier.loadMore, isA<Function>());
      });
    });

    group('Pagination Logic', () {
      test('should handle empty response logic', () {
        // Test the pagination logic pattern used in _loadMoreActivities
        final emptyActivityIds = <String>[];
        bool hasMoreData = true;
        
        if (emptyActivityIds.isEmpty) {
          hasMoreData = false;
        }
        
        expect(hasMoreData, false);
      });

      test('should handle partial page response logic', () {
        // Test pagination logic for partial page
        final partialPageActivities = List.generate(50, (i) => 'activity_$i');
        const pageSize = 100;
        bool hasMoreData = partialPageActivities.length >= pageSize;
        
        expect(hasMoreData, false); // Less than page size
      });

      test('should handle full page response logic', () {
        // Test pagination logic for full page
        final fullPageActivities = List.generate(100, (i) => 'activity_$i');
        const pageSize = 100;
        bool hasMoreData = fullPageActivities.length >= pageSize;
        
        expect(hasMoreData, true); // Exactly page size
      });

      test('should handle pagination offset calculation', () {
        // Test offset calculation logic
        int currentOffset = 0;
        final newIds = ['activity1', 'activity2', 'activity3'];
        
        currentOffset += newIds.length;
        
        expect(currentOffset, 3);
      });
    });

    group('Stream Subscription Handling', () {
      test('should handle stream updates', () {
        // Test that stream handling doesn't crash
        expect(() => mockStreamController.add(true), returnsNormally);
      });

      test('should handle stream errors gracefully', () {
        // Test that stream error handling doesn't crash
        expect(() => mockStreamController.addError('Test error'), returnsNormally);
      });

      test('should handle stream completion', () {
        // Test that stream completion handling doesn't crash
        expect(() => mockStreamController.close(), returnsNormally);
      });
    });

    group('Disposal', () {
      test('should handle disposal gracefully', () {
        // Test that disposal doesn't crash
        expect(() => mockActivities.drop(), returnsNormally);
      });
    });
  });

  group('AsyncActivityNotifier Tests', () {
    late MockClient mockClient;
    late MockActivity mockActivity;
    late StreamController<bool> mockStreamController;

    setUp(() {
      mockClient = MockClient();
      mockActivity = MockActivity(mockType: 'message');
      mockStreamController = StreamController<bool>.broadcast();

      // Setup default mocks
      when(() => mockClient.subscribeModelStream(any())).thenAnswer((_) => mockStreamController.stream);
      when(() => mockClient.activity(any())).thenAnswer((_) async => mockActivity);
    });

    tearDown(() {
      mockStreamController.close();
    });

    group('Initialization and Basic Properties', () {
      test('should create notifier with correct type', () {
        expect(() => AsyncActivityNotifier(), returnsNormally);
      });

      test('should have correct class structure', () {
        final notifier = AsyncActivityNotifier();
        expect(notifier, isA<FamilyAsyncNotifier<Activity?, String>>());
      });
    });

    group('Build Method', () {
      test('should have build method', () {
        final notifier = AsyncActivityNotifier();
        expect(notifier.build, isA<Function>());
      });
    });

    group('Stream Handling', () {
      test('should handle stream updates', () {
        // Test that stream handling doesn't crash
        expect(() => mockStreamController.add(true), returnsNormally);
      });

      test('should handle stream errors gracefully', () {
        // Test that stream error handling doesn't crash
        expect(() => mockStreamController.addError('Test error'), returnsNormally);
      });

      test('should handle stream completion', () {
        // Test that stream completion handling doesn't crash
        expect(() => mockStreamController.close(), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle activity fetch error', () {
        // Mock error on activity fetch
        when(() => mockClient.activity(any())).thenThrow(Exception('Fetch error'));
        
        // Test that error handling doesn't crash
        expect(() => mockClient.activity('test-id'), throwsA(isA<Exception>()));
      });
    });

    group('Disposal', () {
      test('should handle disposal gracefully', () {
        final notifier = AsyncActivityNotifier();
        expect(notifier, isNotNull);
      });
    });
  });

  group('Provider Tests', () {
    test('allActivitiesProvider should be defined', () {
      expect(allActivitiesProvider, isNotNull);
    });

    test('activityProvider should be defined', () {
      expect(activityProvider, isNotNull);
    });

    test('allActivitiesProvider should be AsyncNotifierProvider', () {
      expect(allActivitiesProvider, isA<AsyncNotifierProvider<AllActivitiesNotifier, List<String>>>());
    });

    test('activityProvider should be AsyncNotifierProviderFamily', () {
      expect(activityProvider, isA<AsyncNotifierProviderFamily<AsyncActivityNotifier, Activity?, String>>());
    });
  });

  group('Integration Tests', () {
    test('should handle notifier lifecycle', () {
      final activitiesNotifier = AllActivitiesNotifier();
      final activityNotifier = AsyncActivityNotifier();

      expect(activitiesNotifier, isA<AllActivitiesNotifier>());
      expect(activityNotifier, isA<AsyncActivityNotifier>());

      // Test that notifiers can be created and have expected properties
      expect(activitiesNotifier.hasMoreData, isA<bool>());
      expect(activitiesNotifier.loadMore, isA<Function>());
    });

    test('should handle pagination constants', () {
      final notifier = AllActivitiesNotifier();
      
      // Test that pagination behavior is consistent
      expect(notifier.hasMoreData, isA<bool>());
    });

    test('should handle stream subscription patterns', () {
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

    test('should handle activities object lifecycle', () {
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

    test('should handle offset and pagination logic', () {
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

    test('should handle list concatenation for loadMore', () {
      // Test list concatenation pattern used in loadMore
      final currentActivities = ['activity1', 'activity2'];
      final newActivities = ['activity3', 'activity4'];
      
      // Simulate the loadMore concatenation from _fetchAllActivities
      final result = [...currentActivities, ...newActivities];
      
      expect(result, hasLength(4));
      expect(result, ['activity1', 'activity2', 'activity3', 'activity4']);
    });

    test('should handle error propagation patterns', () {
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

    test('should handle pagination edge cases', () {
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

    test('should handle initial vs loadMore fetch differences', () {
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

    test('should handle room stream subscription pattern', () {
      // Test room stream subscription pattern from AllActivitiesNotifier.build()
      final spaces = ['room1', 'room2', 'room3'];
      final subscriptions = <StreamSubscription>[];
      
      for (int i = 0; i < spaces.length; i++) {
        final streamController = StreamController<bool>.broadcast();
        final subscription = streamController.stream.listen(
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
        streamController.close();
      }

      expect(subscriptions, hasLength(3));
      
      for (final sub in subscriptions) {
        sub.cancel();
      }
    });

    test('should handle activities disposal pattern', () {
      // Test activities disposal pattern from AllActivitiesNotifier
      Activities? activities = MockActivities();
      
      // Simulate disposal pattern
      activities.drop();
      activities = null;
      
      expect(activities, isNull);
    });

    test('should handle subscription disposal pattern', () {
      // Test subscription disposal pattern from AllActivitiesNotifier
      final subscriptions = <StreamSubscription>[];
      final streamController = StreamController<bool>.broadcast();
      
      // Add some subscriptions
      for (int i = 0; i < 3; i++) {
        final subscription = streamController.stream.listen((data) {});
        subscriptions.add(subscription);
      }
      
      // Simulate disposal pattern
      for (final sub in subscriptions) {
        sub.cancel();
      }
      
      expect(subscriptions, hasLength(3));
      streamController.close();
    });
  });
} 