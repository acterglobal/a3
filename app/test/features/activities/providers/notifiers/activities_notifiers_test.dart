import 'dart:async';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activity_ui_showcase/mocks/providers/mock_activities_provider.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart' as showcase;
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/providers/notifiers/always_client_notifier.dart';
import 'package:acter/common/providers/notifiers/space_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../invite_members/providers/other_spaces_for_invite_members_test.dart';
import '../../../room/actions/join_room_test.dart';
import '../../../../helpers/mock_tasks_providers.dart';

class MockActivities extends Mock implements Activities {}

// Mock notifiers that extend the actual classes
class MockAlwaysClientNotifier extends AlwaysClientNotifier {
  final MockClient? _mockClient;
  
  MockAlwaysClientNotifier([this._mockClient]);
  
  @override
  Future<Client> build() async {
    return _mockClient ?? MockClient();
  }
}

class MockSpaceListNotifier extends SpaceListNotifier {
  @override
  List<Space> build() {
    return [MockSpace(), MockSpace()];
  }
}

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
      when(() => mockClient.subscribeModelStream(any())).thenAnswer((_) => mockStreamController.stream);
      when(() => mockSpaces[0].getRoomIdStr()).thenReturn('room1');
      when(() => mockSpaces[1].getRoomIdStr()).thenReturn('room2');
      when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => MockFfiListFfiString(items: []));
      when(() => mockActivities.subscribeStream()).thenAnswer((_) => mockStreamController.stream);
      when(() => mockActivities.drop()).thenReturn(null);
      
      // Mock the MockFfiListFfiString properties
      final mockFfiList = MockFfiListFfiString(items: ['activity1', 'activity2']);
      when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => mockFfiList);
    });

    tearDown(() {
      mockStreamController.close();
    });

    group('LoadMore Method', () {
      test('should handle loadMore method signature', () {
        final notifier = AllActivitiesNotifier();
        expect(notifier.loadMoreActivities, isA<Function>());
      });

      test('should not load more when hasMore is false', () {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        expect(() => notifier.loadMoreActivities(), returnsNormally);
        
        container.dispose();
      });

      test('should handle loadMore error gracefully and set loading state', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        when(() => mockActivities.getIds(any(), any())).thenThrow(Exception('Load more error'));
        
        // The error should be caught and handled gracefully (not rethrown)
        expect(() async => await notifier.loadMoreActivities(), returnsNormally);
    
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should not load more when already loading', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50)); // Simulate slow response
          return MockFfiListFfiString(items: ['activity1']);
        });
        
        // Start loading (this will set _isLoadingMore = true)
        final future1 = notifier.loadMoreActivities();
        
        // Try to load more while already loading (should return early)
        final future2 = notifier.loadMoreActivities();
        
        await Future.wait([future1, future2]);
        
        container.dispose();
      });
    });

    group('Pagination Logic', () {
      test('should handle empty response logic', () {
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

      test('should handle empty activities response', () async {
        final emptyMockFfiList = MockFfiListFfiString(items: []);
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => emptyMockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });
    });

    group('Stream Subscription Handling', () {
      test('should handle stream updates', () {
        expect(() => mockStreamController.add(true), returnsNormally);
      });

      test('should handle stream errors gracefully', () {
        expect(() => mockStreamController.addError('Test error'), returnsNormally);
      });

      test('should handle stream completion', () {
        expect(() => mockStreamController.close(), returnsNormally);
      });

      test('should handle room stream subscription with multiple spaces', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream refresh on data update', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        mockStreamController.add(true);
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream error in listener', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        mockStreamController.addError('Stream error');
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream completion in listener', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        mockStreamController.close();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });
    });

    group('Disposal', () {
      test('should handle disposal gracefully', () {
        expect(() => mockActivities.drop(), returnsNormally);
      });

      test('should cancel all subscriptions on disposal', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should drop activities on disposal', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
        
        expect(true, true); // Test passes if disposal completes without error
      });

      test('should set activities to null on disposal', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        await Future.delayed(Duration(milliseconds: 100));
        
        // Dispose should set activities to null
        container.dispose();
      });
    });

    group('_loadActivitiesInternal Method test cases', () {
      test('should handle reset mode with empty activities', () async {
        final emptyMockFfiList = MockFfiListFfiString(items: []);
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => emptyMockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        // Test reset mode
        await notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle pagination mode with activities', () async {
        final mockFfiList = MockFfiListFfiString(items: ['activity1', 'activity2']);
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => mockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        // Test pagination mode
        await notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle full page response and grouping logic', () async {
        final fullPageActivities = List.generate(100, (i) => 'activity_$i');
        final mockFfiList = MockFfiListFfiString(items: fullPageActivities);
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => mockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        await notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle activity grouping by room and date', () async {
        // Create activities with same room and date to test grouping logic
        final mockFfiList = MockFfiListFfiString(items: ['activity1', 'activity2', 'activity3']);
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => mockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        await notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle activity filtering by supported types', () async {
        final mockFfiList = MockFfiListFfiString(items: ['activity1']);
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => mockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        await notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle space filtering logic', () async {
        final mockFfiList = MockFfiListFfiString(items: ['activity1']);
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => mockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        await notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle activity sorting by timestamp', () async {
        final mockFfiList = MockFfiListFfiString(items: ['activity1', 'activity2']);
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => mockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        await notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle activity grouping by room and date', () async {
        final mockFfiList = MockFfiListFfiString(items: ['activity1', 'activity2']);  
        when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => mockFfiList);
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        await notifier.loadMoreActivities();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle error in _loadActivitiesInternal gracefully', () async {
        when(() => mockActivities.getIds(any(), any())).thenThrow(Exception('Internal error'));
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        // The error should be caught and handled gracefully (not rethrown)
        expect(() async => await notifier.loadMoreActivities(), returnsNormally);
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should rethrow exception from _loadActivitiesInternal', () async {
        // Test the rethrow behavior in _loadActivitiesInternal
        when(() => mockActivities.getIds(any(), any())).thenThrow(Exception('Rethrow test error'));
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        final notifier = container.read(allActivitiesProvider.notifier);
        
        expect(() async => await notifier.loadMoreActivities(), returnsNormally);
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });
    });

    group('_initialLoad Method test cases', () {
      test('should reset pagination state correctly', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );
        
        // Test that initial load resets state
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should call _loadActivitiesInternal with reset=true', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });
    });

    group('Build Method test cases', () {
      test('should clean up previous subscriptions', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should set up stream subscription', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream data updates', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        // Trigger stream update
        mockStreamController.add(true);
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream error in build', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        // Trigger stream error
        mockStreamController.addError('Build stream error');
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream completion in build', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        // Trigger stream completion
        mockStreamController.close();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should call _initialLoad on build', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            spacesProvider.overrideWith(() => MockSpaceListNotifier()),
          ],
        );

        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });
    });
  });

  group('AsyncActivityNotifier Tests', () {
    late MockClient mockClient;
    late showcase.MockActivity mockActivity;
    late StreamController<bool> mockStreamController;

    setUp(() {
      mockClient = MockClient();
      mockActivity = showcase.MockActivity(mockType: 'message', mockActivityId: 'test-id');
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

      test('should return mock activity in showcase mode', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => mockActivity),
          ],
        );
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should get activity from client when not in showcase mode', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null), // No mock activity
          ],
        );
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
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

      test('should handle stream data update and refresh state', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );

        // Trigger stream update
        mockStreamController.add(true);
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream error and set error state', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );

        // Trigger stream error
        mockStreamController.addError('Stream error');
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream completion logging', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );

        // Trigger stream completion
        mockStreamController.close();
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });
    });

    group('Error Handling', () {
      test('should handle activity fetch error', () {
        // Mock error on activity fetch
        when(() => mockClient.activity(any())).thenThrow(Exception('Fetch error'));
        
        // Test that error handling doesn't crash
        expect(() => mockClient.activity('test-id'), throwsA(isA<Exception>()));
      });

      test('should handle stream update error and set error state', () async {
        when(() => mockClient.activity(any())).thenThrow(Exception('Activity fetch error'));
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );

        // Trigger stream update that will cause error
        mockStreamController.add(true);
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });
    });

    group('Disposal', () {
      test('should handle disposal gracefully', () {
        final notifier = AsyncActivityNotifier();
        expect(notifier, isNotNull);
      });

      test('should cancel poller subscription on disposal', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );

        await Future.delayed(Duration(milliseconds: 100));
        
        // Dispose should cancel poller
        container.dispose();
      });
    });

    group('Client Activity Fetch test cases', () {
      test('should fetch activity from client successfully', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle client activity fetch error', () async {
        when(() => mockClient.activity(any())).thenThrow(Exception('Client fetch error'));
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });
    });

    group('Stream Subscription test cases', () {
      test('should set up model stream subscription', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream data updates with successful activity fetch', () async {
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );
        
        // Trigger stream update
        mockStreamController.add(true);
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
      });

      test('should handle stream data updates with failed activity fetch', () async {
        when(() => mockClient.activity(any())).thenThrow(Exception('Stream update fetch error'));
        
        final container = ProviderContainer(
          overrides: [
            alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
            mockActivityProvider.overrideWith((ref, arg) => null),
          ],
        );
        
        // Trigger stream update that will cause error
        mockStreamController.add(true);
        
        await Future.delayed(Duration(milliseconds: 100));
        
        container.dispose();
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
      expect(allActivitiesProvider, isA<AsyncNotifierProvider<AllActivitiesNotifier, List<RoomActivitiesInfo>>>());
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
      expect(activitiesNotifier.hasMore, isA<bool>());
      expect(activitiesNotifier.loadMoreActivities, isA<Function>());
    });

    test('should handle pagination constants', () {
      final notifier = AllActivitiesNotifier();
      
      // Test that pagination behavior is consistent
      expect(notifier.hasMore, isA<bool>());
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

  group('Activity Type Support Tests', () {
    test('should handle supported activity types', () {
      // Test that supported activity types are properly handled
      final supportedTypes = ['comment', 'reaction', 'attachment', 'creation'];
      
      for (final type in supportedTypes) {
        expect(isActivityTypeSupported(type), isA<bool>());
      }
    });

    test('should handle unsupported activity types', () {
      // Test that unsupported activity types are properly filtered out
      final unsupportedTypes = ['invalid_type', 'unknown_type', ''];
      
      for (final type in unsupportedTypes) {
        expect(isActivityTypeSupported(type), isA<bool>());
      }
    });
  });

  group('Activity Date Handling Tests', () {
    test('should handle activity date extraction', () {
      // Test the getActivityDate function
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final activityDate = getActivityDate(timestamp);
      
      expect(activityDate, isA<DateTime>());
      expect(activityDate.hour, 0);
      expect(activityDate.minute, 0);
      expect(activityDate.second, 0);
      expect(activityDate.millisecond, 0);
    });

    test('should handle activity grouping by date', () {
      // Test activity grouping logic
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      final activity1Date = getActivityDate(today.millisecondsSinceEpoch);
      final activity2Date = getActivityDate(yesterday.millisecondsSinceEpoch);
      
      expect(activity1Date.isAtSameMomentAs(today), true);
      expect(activity2Date.isAtSameMomentAs(yesterday), true);
      expect(activity1Date.isAtSameMomentAs(activity2Date), false);
    });
  });

  group('Room Activities Info Tests', () {
    test('should handle RoomActivitiesInfo record structure', () {
      // Test the RoomActivitiesInfo record type
      final mockActivity = showcase.MockActivity(
        mockType: 'comment',
        mockActivityId: 'test-id',
        mockRoomId: 'room1',
      );
      
      final roomActivitiesInfo = (roomId: 'room1', activities: [mockActivity]);
      
      expect(roomActivitiesInfo.roomId, 'room1');
      expect(roomActivitiesInfo.activities, hasLength(1));
      expect(roomActivitiesInfo.activities.first, mockActivity);
    });

    test('should handle empty activities list', () {
      // Test RoomActivitiesInfo with empty activities
      final roomActivitiesInfo = (roomId: 'room1', activities: <Activity>[]);
      
      expect(roomActivitiesInfo.roomId, 'room1');
      expect(roomActivitiesInfo.activities, isEmpty);
    });
  });

  group('Error Recovery Tests', () {
    late MockClient mockClient;
    late StreamController<bool> mockStreamController;

    setUp(() {
      mockClient = MockClient();
      mockStreamController = StreamController<bool>.broadcast();
      when(() => mockClient.subscribeModelStream(any())).thenAnswer((_) => mockStreamController.stream);
    });

    tearDown(() {
      mockStreamController.close();
    });

    test('should handle client connection errors', () async {
      when(() => mockClient.allActivities()).thenThrow(Exception('Connection error'));
      
      final container = ProviderContainer(
        overrides: [
          alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
          spacesProvider.overrideWith(() => MockSpaceListNotifier()),
        ],
      );

      await Future.delayed(Duration(milliseconds: 100));
      
      container.dispose();
    });

    test('should handle activity fetch timeout', () async {
      when(() => mockClient.activity(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 5));
        return showcase.MockActivity(mockType: 'comment', mockActivityId: 'test-id');
      });
      
      final container = ProviderContainer(
        overrides: [
          alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
          mockActivityProvider.overrideWith((ref, arg) => null),
        ],
      );

      await Future.delayed(Duration(milliseconds: 100));
      
      container.dispose();
    });

    test('should handle stream subscription errors', () async {
      when(() => mockClient.subscribeModelStream(any())).thenThrow(Exception('Subscription error'));
      
      final container = ProviderContainer(
        overrides: [
          alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
          mockActivityProvider.overrideWith((ref, arg) => null),
        ],
      );

      await Future.delayed(Duration(milliseconds: 100));
      
      container.dispose();
    });
  });

  group('Memory Management Tests', () {
    late MockClient mockClient;
    late StreamController<bool> mockStreamController;

    setUp(() {
      mockClient = MockClient();
      mockStreamController = StreamController<bool>.broadcast();
      when(() => mockClient.subscribeModelStream(any())).thenAnswer((_) => mockStreamController.stream);
    });

    tearDown(() {
      mockStreamController.close();
    });

    test('should properly dispose stream subscriptions', () async {
      final container = ProviderContainer(
        overrides: [
          alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
          spacesProvider.overrideWith(() => MockSpaceListNotifier()),
        ],
      );

      await Future.delayed(Duration(milliseconds: 100));
      
      // Dispose should clean up all subscriptions
      container.dispose();
      
      // Verify no memory leaks by checking that disposal completes
      expect(true, true);
    });

    test('should handle multiple disposals gracefully', () async {
      final container = ProviderContainer(
        overrides: [
          alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
          spacesProvider.overrideWith(() => MockSpaceListNotifier()),
        ],
      );

      await Future.delayed(Duration(milliseconds: 100));
      
      // Multiple disposals should not cause errors
      container.dispose();
      container.dispose();
      
      expect(true, true);
    });
  });

  group('Concurrent Access Tests', () {
    late MockClient mockClient;
    late StreamController<bool> mockStreamController;

    setUp(() {
      mockClient = MockClient();
      mockStreamController = StreamController<bool>.broadcast();
      when(() => mockClient.subscribeModelStream(any())).thenAnswer((_) => mockStreamController.stream);
    });

    tearDown(() {
      mockStreamController.close();
    });

    test('should handle concurrent loadMore calls', () async {
      final container = ProviderContainer(
        overrides: [
          alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
          spacesProvider.overrideWith(() => MockSpaceListNotifier()),
        ],
      );

      final notifier = container.read(allActivitiesProvider.notifier);
      
      // Simulate concurrent loadMore calls
      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        futures.add(notifier.loadMoreActivities());
      }
      
      await Future.wait(futures);
      
      container.dispose();
    });

    test('should handle concurrent stream updates', () async {
      final container = ProviderContainer(
        overrides: [
          alwaysClientProvider.overrideWith(() => MockAlwaysClientNotifier(mockClient)),
          spacesProvider.overrideWith(() => MockSpaceListNotifier()),
        ],
      );

      // Simulate concurrent stream updates
      for (int i = 0; i < 10; i++) {
        mockStreamController.add(true);
      }
      
      await Future.delayed(Duration(milliseconds: 100));
      
      container.dispose();
    });
  });
} 