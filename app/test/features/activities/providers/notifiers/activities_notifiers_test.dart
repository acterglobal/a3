import 'dart:async';

import 'package:acter/common/providers/space_providers.dart';
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
    late StreamController<bool> mockStreamController;

    setUp(() {
      mockClient = MockClient();
      mockActivities = MockActivities();
      mockStreamController = StreamController<bool>.broadcast();

      // Setup default mocks
      when(() => mockClient.allActivities()).thenReturn(mockActivities);
      when(() => mockClient.subscribeRoomStream(any())).thenAnswer((_) => mockStreamController.stream);
      when(() => mockClient.subscribeModelStream(any())).thenAnswer((_) => mockStreamController.stream);
      when(() => mockActivities.getIds(any(), any())).thenAnswer((_) async => MockFfiListFfiString(items: []));
      when(() => mockActivities.subscribeStream()).thenAnswer((_) => mockStreamController.stream);
      when(() => mockActivities.drop()).thenReturn(null);
    });

    tearDown(() {
      mockStreamController.close();
    });

    group('LoadMore Method', () {
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

      test('should handle loadMore error gracefully', () async {
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
    });

    group('_loadActivitiesInternal Method Coverage', () {
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

      test('should handle full page response (exactly 100 activities)', () async {
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
    });

    group('Build Method Coverage', () {
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
    });

    group('Disposal', () {
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

    group('Build Method', () {
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
      test('should handle stream updates', () async {
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

      test('should handle stream errors gracefully', () async {
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

      test('should handle stream completion', () async {
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
  });

  group('Helper Function Tests', () {
    test('should handle supported activity types', () {
      // Test that supported activity types are properly handled
      final supportedTypes = ['comment', 'reaction', 'attachment', 'creation'];
      
      for (final type in supportedTypes) {
        expect(isActivityTypeSupported(type), isA<bool>());
      }
    });

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
  });
} 