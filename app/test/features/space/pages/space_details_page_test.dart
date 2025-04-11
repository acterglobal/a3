// ignore_for_file: deprecated_member_use

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/scrollable_list_tab_scroller.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/space/pages/space_details_page.dart';
import 'package:acter/features/space/providers/topic_provider.dart';
import 'package:acter/features/space/widgets/space_sections/about_section.dart';
import 'package:acter/features/space/widgets/space_sections/members_section.dart';
import 'package:acter/features/space/widgets/space_sections/news_section.dart';
import 'package:acter/features/space/widgets/space_sections/suggested_chats_section.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_app_settings.dart';
import '../../../helpers/mock_pins_providers.dart';
import '../../../helpers/mock_relations.dart';
import '../../../helpers/mock_room_providers.dart';
import '../../../helpers/mock_space_providers.dart';
import '../../../helpers/mock_updates_providers.dart';
import '../../../helpers/test_util.dart';

class MockItemPositionsListener extends Mock implements ItemPositionsListener {}

class MockMembership extends Mock implements Member {}

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
    late String testSpaceId;
    late MockSpaceRelations mockSpaceRelations;

    setUp(() {
      testSpaceId = 'test-space-id-${DateTime.now().millisecondsSinceEpoch}';
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

    group('Basic rendering', () {
      late List<Override> basicOverrides;
      late List<Override> extendedOverrides;
      setUp(() {
        basicOverrides = [
          roomDisplayNameProvider.overrideWith(
            (ref, spaceId) => spaceId == testSpaceId ? 'Test Space' : null,
          ),
          roomAvatarProvider.overrideWith(
            (ref, spaceId) => spaceId == testSpaceId ? null : null,
          ),
        ];

        extendedOverrides = [
          ...basicOverrides,
          isActerSpace.overrideWith((ref, spaceId) => true),
          topicProvider.overrideWith((ref, spaceId) => 'We have some topic'),
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
        ];
      });

      testWidgets('renders minimal basic page structure', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: basicOverrides,
          child: SpaceDetailsPage(spaceId: testSpaceId),
        );

        // Verify header is present
        final header = find.byKey(SpaceDetailsPage.headerKey);
        expect(header, findsOneWidget);
        final BuildContext context = tester.element(header);
        final lang = L10n.of(context);

        // Verify we can see the members tab
        expect(find.text(lang.members), findsOneWidget);
      });

      testWidgets('renders feature tabs', (WidgetTester tester) async {
        await tester.pumpProviderWidget(
          overrides: extendedOverrides,
          child: SpaceDetailsPage(spaceId: testSpaceId),
        );

        // Verify header is present
        final header = find.byKey(SpaceDetailsPage.headerKey);
        expect(header, findsOneWidget);
        final BuildContext context = tester.element(header);
        final lang = L10n.of(context);

        // Verify tabs are rendered
        expect(find.text(lang.overview), findsOneWidget);
        expect(find.text('We have some topic'), findsOneWidget);
        expect(find.text(lang.updates), findsAtLeast(1));
        expect(find.text(lang.pins), findsAtLeast(1));
        expect(find.text(lang.tasks), findsAtLeast(1));
        expect(find.text(lang.events), findsAtLeast(1));
        expect(find.text(lang.suggestedSpaces), findsNothing);
        expect(find.text(lang.members), findsAtLeast(1));
      });
      testWidgets('renders different sections based on active tab', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: extendedOverrides,
          child: SpaceDetailsPage(spaceId: testSpaceId),
        );

        // Initially should show overview section
        final about = find.byType(AboutSection);
        expect(about, findsOneWidget);

        final BuildContext context = tester.element(about);
        final lang = L10n.of(context);

        // Tap on updates tab
        await tester.tap(find.text(lang.updates).first);
        await tester.pump(const Duration(seconds: 2));

        // Should show updates section
        expect(find.byType(NewsSection), findsOneWidget);

        // Tap on members tab
        final members = find.text(lang.members).first;
        await tester.ensureVisible(members);
        await tester.tap(members);
        await tester.pump();

        // Should show members section
        expect(find.byType(MembersSection), findsOneWidget);
      });

      testWidgets('renders spaces and chat tabs', (WidgetTester tester) async {
        await tester.pumpProviderWidget(
          overrides: [
            ...extendedOverrides,
            spaceProvider(testSpaceId).overrideWith((ref) async => MockSpace()),
            maybeRoomProvider.overrideWith(
              () => MockAlwaysTheSameRoomNotifier(room: MockRoom()),
            ),
            spaceRelationsProvider(
              testSpaceId,
            ).overrideWith((ref) async => mockSpaceRelations),
          ],
          child: SpaceDetailsPage(spaceId: testSpaceId),
        );

        // Verify header is present
        final header = find.byKey(SpaceDetailsPage.headerKey);
        expect(header, findsOneWidget);
        final BuildContext context = tester.element(header);
        final lang = L10n.of(context);

        // Verify tabs are rendered
        expect(find.text(lang.overview), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));

        // what we care for in this stest
        expect(
          find.text(lang.suggestedSpaces, skipOffstage: false),
          findsAtLeast(1),
        );
        expect(
          find.text(lang.suggestedChats, skipOffstage: false),
          findsAtLeast(1),
        );
        expect(find.text(lang.spaces, skipOffstage: false), findsAtLeast(1));
        expect(find.text(lang.chats, skipOffstage: false), findsAtLeast(1));
      });
    });
    group('Tab Provider Changes updates properly', () {
      const testSpaceId = 'test-space-id';
      late MockMembership mockMembership;
      late MockRoom mockRoom;
      late MockSpace mockSpace;

      setUp(() {
        mockMembership = MockMembership();
        mockRoom = MockRoom();
        mockSpace = MockSpace();
      });

      testWidgets('refreshes space relations upon refresh', (
        WidgetTester tester,
      ) async {
        bool failSpaceRelations = true;

        final overrides = [
          roomDisplayNameProvider.overrideWith(
            (ref, spaceId) => spaceId == testSpaceId ? 'Test Space' : null,
          ),
          roomAvatarProvider.overrideWith(
            (ref, spaceId) => spaceId == testSpaceId ? null : null,
          ),
          spaceProvider(testSpaceId).overrideWith((ref) async => mockSpace),
          maybeRoomProvider.overrideWith(
            () => MockAlwaysTheSameRoomNotifier(room: mockRoom),
          ),

          spaceRelationsProvider(testSpaceId).overrideWith((ref) async {
            //emulate the connection
            await ref.watch(spaceProvider(testSpaceId).future);
            if (failSpaceRelations) {
              throw Exception('Failed to load space relations');
            }
            return mockSpaceRelations;
          }),
          isActerSpace.overrideWith((ref, spaceId) => true),
          topicProvider.overrideWith((ref, spaceId) => 'We have some topic'),
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
        ];

        await tester.pumpProviderWidget(
          overrides: overrides,
          child: SpaceDetailsPage(spaceId: testSpaceId),
        );

        final context = tester.element(find.byType(SpaceDetailsPage));
        final lang = L10n.of(context);

        expect(find.text(lang.overview), findsOneWidget);
        expect(find.text('We have some topic'), findsOneWidget);
        expect(find.text(lang.updates), findsAtLeast(1));
        expect(find.text(lang.pins), findsAtLeast(1));
        expect(find.text(lang.tasks), findsAtLeast(1));
        expect(find.text(lang.events), findsAtLeast(1));
        expect(find.text(lang.members), findsAtLeast(1));

        // this failed!

        expect(find.text(lang.spaces), findsNothing);
        expect(find.text(lang.chats), findsNothing);
        expect(find.text(lang.suggestedChats), findsNothing);
        expect(find.text(lang.suggestedSpaces), findsNothing);

        // make it not fail
        failSpaceRelations = false;

        // Pull to refresh
        await tester.drag(
          find.byType(ScrollableListTabScroller),
          const Offset(0, 350),
        );

        await tester.pump(
          const Duration(seconds: 1),
        ); // finish the scroll animation
        await tester.pump(
          const Duration(seconds: 1),
        ); // finish the indicator settle animation
        await tester.pump(
          const Duration(seconds: 1),
        ); // finish the indicator hide animation

        expect(find.text(lang.spaces), findsAtLeast(1));
        expect(find.text(lang.chats), findsAtLeast(1));
        expect(find.text(lang.suggestedChats), findsAtLeast(1));
        expect(find.text(lang.suggestedSpaces), findsAtLeast(1));
      });
      testWidgets('when news are activated', (tester) async {
        when(() => mockMembership.canString(any())).thenReturn(true);

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
