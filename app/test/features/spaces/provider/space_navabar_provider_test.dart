import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/providers/topic_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_app_settings.dart';
import '../../../helpers/mock_pins_providers.dart';
import '../../../helpers/mock_relations.dart';
import '../../../helpers/mock_room_providers.dart';
import '../../../helpers/mock_updates_providers.dart';

class MockSpaceHierarchyRoomInfo extends Mock
    implements SpaceHierarchyRoomInfo {}

void main() {
  group('SpaceNavbarProvider', () {
    late ProviderContainer container;
    late String testSpaceId;
    late MockSpaceRelations mockSpaceRelations;

    setUp(() {
      container = ProviderContainer();
      testSpaceId = 'test-space-id-${Random().nextInt(1000000)}';
      mockSpaceRelations = MockSpaceRelations(
        roomId: testSpaceId,
        children: [
          MockSpaceRelation(roomId: 'subspace1', targetType: 'Space'),
          MockSpaceRelation(roomId: 'chat1', targetType: 'ChatRoom'),
          MockSpaceRelation(
            roomId: 'suggested1',
            targetType: 'Space',
            suggested: true,
          ),
          MockSpaceRelation(
            roomId: 'suggested2',
            targetType: 'ChatRoom',
            suggested: true,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Shows tabs based for acter spaces features', () {
      final basicOverrides = [
        topicProvider.overrideWith(
          (ref, spaceId) => spaceId == testSpaceId ? 'Test Topic' : null,
        ),
        isActerSpace.overrideWith(
          (ref, spaceId) => spaceId == testSpaceId ? true : false,
        ),
      ];
      test('show overview if it exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(overrides: [...basicOverrides]);

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, equals([TabEntry.overview, TabEntry.members]));
      });

      test('shows only members if nothing exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            topicProvider.overrideWith((ref, spaceId) => null),
            isActerSpace.overrideWith((ref, spaceId) => true),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, equals([TabEntry.members]));
      });

      group('updates', () {
        test('shows if any exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              updateListProvider.overrideWith(
                (ref, spaceId) => [MockUpdatesEntry()],
              ),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: true,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(
            next,
            equals([TabEntry.overview, TabEntry.updates, TabEntry.members]),
          );
        });

        test('hides if none exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              updateListProvider.overrideWith((ref, spaceId) => []),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: true,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });

        test('hides if exists but deactivated', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              updateListProvider.overrideWith(
                (ref, spaceId) => [MockUpdatesEntry()], // we have an update
              ),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false, // updates have been deactivated
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });
      });

      group('pins', () {
        test('shows if any exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              pinListProvider.overrideWith((ref, spaceId) => [MockActerPin()]),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: true,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(
            next,
            equals([TabEntry.overview, TabEntry.pins, TabEntry.members]),
          );
        });

        test('hides if none exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              pinListProvider.overrideWith((ref, spaceId) => []),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: true,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });

        test('hides if exists but deactivated', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              pinListProvider.overrideWith((ref, spaceId) => [MockActerPin()]),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });
      });

      group('tasks', () {
        test('shows if any exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              taskListsProvider.overrideWith((ref, spaceId) => ['a']),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: true,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(
            next,
            equals([TabEntry.overview, TabEntry.tasks, TabEntry.members]),
          );
        });

        test('hides if none exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              taskListsProvider.overrideWith((ref, spaceId) => []),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: true,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });

        test('hides if exists but deactivated', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              taskListsProvider.overrideWith((ref, spaceId) => ['a']),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });
      });

      group('events', () {
        test('shows if any exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              allEventListProvider.overrideWith(
                (ref, spaceId) => [MockCalendarEvent()],
              ),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: true,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(
            next,
            equals([TabEntry.overview, TabEntry.events, TabEntry.members]),
          );
        });

        test('hides if none exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              allEventListProvider.overrideWith((ref, spaceId) => []),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: true,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });

        test('hides if exists but deactivated', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              allEventListProvider.overrideWith(
                (ref, spaceId) => [MockCalendarEvent()],
              ),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });
      });

      test('shows all if enabled and exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            allEventListProvider.overrideWith(
              (ref, spaceId) => [MockCalendarEvent()],
            ),
            updateListProvider.overrideWith(
              (ref, spaceId) => [MockUpdatesEntry()],
            ),
            pinListProvider.overrideWith((ref, spaceId) => [MockActerPin()]),
            taskListsProvider.overrideWith((ref, spaceId) => ['a']),
            acterAppSettingsProvider.overrideWith(
              (ref, spaceId) => MockActerAppSettings(
                newsActive: true,
                pinsActive: true,
                tasksActive: true,
                eventsActive: true,
              ),
            ),
          ],
        );
        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(
          next,
          equals([
            TabEntry.overview,
            TabEntry.updates,
            TabEntry.pins,
            TabEntry.tasks,
            TabEntry.events,
            TabEntry.members,
          ]),
        );
      });

      test('hides all if exists but not an acter space', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            topicProvider.overrideWith((ref, spaceId) => 'Test Topic'),
            isActerSpace.overrideWith(
              (ref, spaceId) => false,
            ), // this disable all them
            allEventListProvider.overrideWith(
              (ref, spaceId) => [MockCalendarEvent()],
            ),
            updateListProvider.overrideWith(
              (ref, spaceId) => [MockUpdatesEntry()],
            ),
            pinListProvider.overrideWith((ref, spaceId) => [MockActerPin()]),
            taskListsProvider.overrideWith((ref, spaceId) => ['a']),
          ],
        );
        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, equals([TabEntry.overview, TabEntry.members]));
      });
    });

    group('Shows tabs based for non acter spaces', () {
      test('show overview if it exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            topicProvider.overrideWith((ref, spaceId) => 'Test Topic'),
            isActerSpace.overrideWith((ref, spaceId) => false),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, contains(TabEntry.overview));
        expect(next, contains(TabEntry.members));
      });

      test('shows only members if nothing exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            topicProvider.overrideWith((ref, spaceId) => null),
            isActerSpace.overrideWith((ref, spaceId) => false),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, equals([TabEntry.members]));
      });
    });

    group('Shows tabs for children', () {
      final basicOverrides = [
        topicProvider.overrideWith(
          (ref, spaceId) => spaceId == testSpaceId ? 'Test Topic' : null,
        ),
        isActerSpace.overrideWith(
          (ref, spaceId) => spaceId == testSpaceId ? true : false,
        ),
      ];

      test('shows suggested chats when available', () async {
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            suggestedChatsProvider.overrideWith(
              (ref, spaceId) => (
                ['chat1'],
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, contains(TabEntry.suggestedChats));
      });

      test('shows suggested spaces when available', () async {
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            suggestedSpacesProvider.overrideWith(
              (ref, spaceId) => (
                ['space1'],
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
          ],
        );
        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, contains(TabEntry.suggestedSpaces));
      });

      test('shows chats when available', () async {
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            otherChatsProvider.overrideWith(
              (ref, spaceId) => (
                ['chat1'],
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, contains(TabEntry.chats));
      });

      test('shows spaces when available', () async {
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            otherSubSpacesProvider.overrideWith(
              (ref, spaceId) => (
                ['space1'],
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, contains(TabEntry.spaces));
      });

      test('shows all child space tabs when all are available', () async {
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            suggestedChatsProvider.overrideWith(
              (ref, spaceId) => (
                ['chat1'],
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
            suggestedSpacesProvider.overrideWith(
              (ref, spaceId) => (
                ['space1'],
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
            otherChatsProvider.overrideWith(
              (ref, spaceId) => (
                ['chat2'],
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
            otherSubSpacesProvider.overrideWith(
              (ref, spaceId) => (
                ['space2'],
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(
          next,
          containsAll([
            TabEntry.suggestedChats,
            TabEntry.suggestedSpaces,
            TabEntry.chats,
            TabEntry.spaces,
          ]),
        );
      });

      test('shows all child space tabs from space relations', () async {
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            maybeRoomProvider.overrideWith(
              () => MockAlwaysTheSameRoomNotifier(room: MockRoom()),
            ),
            spaceRelationsProvider(
              testSpaceId,
            ).overrideWith((ref) async => mockSpaceRelations),
          ],
        );
        // cached
        // ignore: unused_local_variable
        final first = container.read(tabsProvider(testSpaceId));

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(
          next,
          containsAll([
            TabEntry.suggestedChats,
            TabEntry.suggestedSpaces,
            TabEntry.chats,
            TabEntry.spaces,
          ]),
        );
      });
      test('hides child space tabs when none are available', () async {
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            suggestedChatsProvider.overrideWith(
              (ref, spaceId) => (
                List<String>.empty(),
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
            suggestedSpacesProvider.overrideWith(
              (ref, spaceId) => (
                List<String>.empty(),
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
            otherChatsProvider.overrideWith(
              (ref, spaceId) => (
                List<String>.empty(),
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
            otherSubSpacesProvider.overrideWith(
              (ref, spaceId) => (
                List<String>.empty(),
                List<MockSpaceHierarchyRoomInfo>.empty(),
              ),
            ),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, isNot(contains(TabEntry.suggestedChats)));
        expect(next, isNot(contains(TabEntry.suggestedSpaces)));
        expect(next, isNot(contains(TabEntry.chats)));
        expect(next, isNot(contains(TabEntry.spaces)));
      });

      test('shows tabs when room infos element has items', () async {
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            suggestedChatsProvider.overrideWith(
              (ref, spaceId) => (
                List<String>.empty(),
                [MockSpaceHierarchyRoomInfo()],
              ),
            ),
            suggestedSpacesProvider.overrideWith(
              (ref, spaceId) => (
                List<String>.empty(),
                [MockSpaceHierarchyRoomInfo()],
              ),
            ),
            otherChatsProvider.overrideWith(
              (ref, spaceId) => (
                List<String>.empty(),
                [MockSpaceHierarchyRoomInfo()],
              ),
            ),
            otherSubSpacesProvider.overrideWith(
              (ref, spaceId) => (
                List<String>.empty(),
                [MockSpaceHierarchyRoomInfo()],
              ),
            ),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(
          next,
          containsAll([
            TabEntry.suggestedChats,
            TabEntry.suggestedSpaces,
            TabEntry.chats,
            TabEntry.spaces,
          ]),
        );
      });
    });
  });
}
