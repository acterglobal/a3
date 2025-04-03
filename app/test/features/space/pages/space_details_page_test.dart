// ignore_for_file: deprecated_member_use

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/space/pages/space_details_page.dart';
import 'package:acter/features/space/widgets/space_sections/about_section.dart';
import 'package:acter/features/space/widgets/space_sections/members_section.dart';
import 'package:acter/features/space/widgets/space_sections/news_section.dart';
import 'package:acter/features/space/widgets/space_sections/suggested_chats_section.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:test_screenshot/test_screenshot.dart';
import '../../../helpers/mock_room_providers.dart';
import '../../../helpers/mock_space_providers.dart';
import '../../../helpers/mock_updates_providers.dart';
import '../../../helpers/test_util.dart';

class MockItemPositionsListener extends Mock implements ItemPositionsListener {}

class MockMembership extends Mock implements Member {}

class MockActerAppSettings extends Mock implements ActerAppSettings {
  final bool newsActive;
  final bool storiesActive;
  final bool pinsActive;
  final bool tasksActive;
  final bool eventsActive;

  MockActerAppSettings({
    this.newsActive = false,
    this.storiesActive = false,
    this.pinsActive = false,
    this.tasksActive = false,
    this.eventsActive = false,
  });

  @override
  NewsSettings news() => MockNewsSettings(on: newsActive);

  @override
  StoriesSettings stories() => MockStoriesSettings(on: storiesActive);

  @override
  PinsSettings pins() => MockPinsSettings(on: pinsActive);

  @override
  TasksSettings tasks() => MockTasksSettings(on: tasksActive);

  @override
  EventsSettings events() => MockEventsSettings(on: eventsActive);
}

class MockNewsSettings extends Mock implements NewsSettings {
  final bool on;
  MockNewsSettings({this.on = false});
  @override
  bool active() => on;
}

class MockStoriesSettings extends Mock implements StoriesSettings {
  final bool on;
  MockStoriesSettings({this.on = false});
  @override
  bool active() => on;
}

class MockPinsSettings extends Mock implements PinsSettings {
  final bool on;
  MockPinsSettings({this.on = false});
  @override
  bool active() => on;
}

class MockTasksSettings extends Mock implements TasksSettings {
  final bool on;
  MockTasksSettings({this.on = false});
  @override
  bool active() => on;
}

class MockEventsSettings extends Mock implements EventsSettings {
  final bool on;
  MockEventsSettings({this.on = false});
  @override
  bool active() => on;
}

class MockRoom extends Mock implements Room {}

class MockActerPin extends Mock implements ActerPin {}

class MockCalendarEvent extends Mock implements CalendarEvent {}

class MockTaskList extends Mock implements TaskList {}

// class MockRoomInfo extends Mock implements RoomInfo {}

class MockSpaceHierarchyRoomInfo extends Mock
    implements SpaceHierarchyRoomInfo {
  final String roomId;
  final String? named;
  final String joinRule;
  final List<String> serverNames;
  final bool isSuggested;

  MockSpaceHierarchyRoomInfo({
    required this.roomId,
    this.named,
    this.joinRule = 'Private',
    this.isSuggested = false,
    this.serverNames = const [],
  });

  @override
  String roomIdStr() => roomId;

  @override
  String? name() => named;

  @override
  String joinRuleStr() => joinRule;

  @override
  MockFfiListFfiString viaServerNames() =>
      MockFfiListFfiString(items: serverNames);

  @override
  bool suggested() => isSuggested;
}

class MockFfiListFfiString extends Mock implements FfiListFfiString {
  final List<String> items;
  MockFfiListFfiString({required this.items});
  // @override
  // List<String> toDartList() => items;
}

class MockSpace extends Mock implements Space {}

void main() {
  group('SpaceDetailsPage', () {
    const testSpaceId = 'test-space-id';
    late MockMembership mockMembership;
    late MockRoom mockRoom;
    late MockSpace mockSpace;

    setUp(() {
      mockMembership = MockMembership();
      mockRoom = MockRoom();
      mockSpace = MockSpace();
    });

    group('Tab Provider Changes updates properly', () {
      testWidgets('when news are activated', (tester) async {
        when(() => mockMembership.canString(any())).thenReturn(true);
        await tester.loadFonts();

        when(
          () => mockSpace.isActerSpace(),
        ).thenAnswer((_) => Future.value(true));

        bool active = false;
        when(() => mockSpace.appSettings()).thenAnswer(
          (_) => Future.value(
            MockActerAppSettings(
              newsActive: active,
              pinsActive: false,
              tasksActive: false,
              eventsActive: false,
            ),
          ),
        );
        when(() => mockRoom.topic()).thenReturn('Test Topic');
        await tester.pumpProviderWidget(
          overrides: [
            maybeSpaceProvider.overrideWith(
              () => RetryMockAsyncSpaceNotifier(
                mockSpace: mockSpace,
                shouldFail: false,
              ),
            ),
            maybeRoomProvider.overrideWith(
              () => MockAlwaysTheSameRoomNotifier(room: mockRoom),
            ),
            updateListProvider.overrideWith(
              (ref, spaceId) => Future.value([MockUpdatesEntry()]),
            ),
            pinListProvider.overrideWith(
              (ref, spaceId) => Future.value([MockActerPin()]),
            ),
            taskListsProvider.overrideWith(
              (ref, spaceId) => Future.value(['id']),
            ),
            allEventListProvider.overrideWith(
              (ref, spaceId) => Future.value([MockCalendarEvent()]),
            ),
            suggestedChatsProvider.overrideWith(
              (ref, spaceId) => Future.value((
                List<String>.empty(),
                List<SpaceHierarchyRoomInfo>.empty(),
              )),
            ),
            suggestedSpacesProvider.overrideWith(
              (ref, spaceId) => Future.value((
                List<String>.empty(),
                List<SpaceHierarchyRoomInfo>.empty(),
              )),
            ),
            otherChatsProvider.overrideWith(
              (ref, spaceId) => Future.value((
                List<String>.empty(),
                List<SpaceHierarchyRoomInfo>.empty(),
              )),
            ),
            otherSubSpacesProvider.overrideWith(
              (ref, spaceId) => Future.value((
                List<String>.empty(),
                List<SpaceHierarchyRoomInfo>.empty(),
              )),
            ),
          ],
          child: const SpaceDetailsPage(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.byType(AboutSection), findsOneWidget);
        expect(find.byType(MembersSection), findsOneWidget);
        expect(find.byType(NewsSection), findsNothing);
        expect(find.byType(SuggestedChatsSection), findsNothing);

        final context = tester.element(find.byType(SpaceDetailsPage));
        final container = ProviderScope.containerOf(context);

        // let's override the app settings
        active = true;
        // and make sure the provider refresh them
        container.invalidate(acterAppSettingsProvider(testSpaceId));

        await tester.pump();
        await tester.pump();
        await tester.pump();

        // shown now!
        expect(find.byType(NewsSection, skipOffstage: false), findsOneWidget);

        // and about section is still there, too
        expect(find.byType(AboutSection, skipOffstage: false), findsOneWidget);
      });
    });
  });
}
