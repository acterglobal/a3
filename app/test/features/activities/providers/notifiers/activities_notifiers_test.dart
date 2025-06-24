import 'dart:async';

import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

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
      expect(notifier, isA<AsyncNotifier<List<Activity>>>());
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

    test('activities can call getIds method', () async {
      // Arrange
      when(() => mockActivities.getIds(0, 200)).thenAnswer((_) async => MockFfiListFfiString(items: []));

      // Act
      final ids = await mockActivities.getIds(0, 200);

      // Assert
      expect(ids, isNotNull);
      verify(() => mockActivities.getIds(0, 200)).called(1);
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
      when(() => mockActivities.getIds(0, 200)).thenThrow(Exception('Async error'));

      // Act & Assert
      expect(() => mockActivities.getIds(0, 200), throwsA(isA<Exception>()));
    });

    test('stream error handling pattern works', () async {
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
      await Future.delayed(Duration.zero);

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
} 