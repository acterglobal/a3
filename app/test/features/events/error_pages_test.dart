import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/events/pages/event_details_page.dart';
import 'package:acter/features/events/pages/event_list_page.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/error_helpers.dart';
import '../../helpers/mock_event_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    String? spaceId,
    String? searchText,
  }) async {
    bool shouldFail = true;
    await tester.pumpProviderWidget(
      overrides: [
        allUpcomingEventListWithSearchProvider.overrideWith((a, b) {
          if (shouldFail) {
            // toggle failure so the retry works
            shouldFail = !shouldFail;
            throw 'Expected fail: Space not loaded';
          }
          return [];
        }),
        allOngoingEventListWithSearchProvider.overrideWith((a, b) {
          if (shouldFail) {
            // toggle failure so the retry works
            shouldFail = !shouldFail;
            throw 'Expected fail: Space not loaded';
          }
          return [];
        }),
        allPastEventListWithSearchProvider.overrideWith((a, b) {
          if (shouldFail) {
            // toggle failure so the retry works
            shouldFail = !shouldFail;
            throw 'Expected fail: Space not loaded';
          }
          return [];
        }),
        bookmarkedEventListProvider.overrideWith((a, b) {
          if (shouldFail) {
            // toggle failure so the retry works
            shouldFail = !shouldFail;
            throw 'Expected fail: Space not loaded';
          }
          return [];
        }),
        searchValueProvider.overrideWith((_) => searchText ?? ''), // set a search string
        roomDisplayNameProvider.overrideWith((a, b) => 'test'),
        roomMembershipProvider.overrideWith((a, b) => null),
        hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
      ],
      child: EventListPage(
        spaceId: spaceId,
      ),
    );
    await tester.ensureErrorPageWithRetryWorks();
  }

  group('Event List Error Pages', () {
    testWidgets('All event list', (tester) async {
      createWidgetUnderTest(tester: tester);
    });
    testWidgets('All event list : with search', (tester) async {
      createWidgetUnderTest(tester: tester, searchText: 'some string');
    });
    testWidgets('Space event list', (tester) async {
      createWidgetUnderTest(tester: tester, spaceId: '!test');
    });
    testWidgets('Space event list : with search', (tester) async {
      createWidgetUnderTest(
        tester: tester,
        spaceId: 'spaceId',
        searchText: 'some string',
      );
    });
  });
  group('Event Details Error Pages', () {
    testWidgets('body error page', (tester) async {
      final mockedNofitier = MockAsyncCalendarEventNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          isBookmarkedProvider.overrideWith((a, b) => false),
          calendarEventProvider.overrideWith(() => mockedNofitier),
          participantsProvider
              .overrideWith(() => MockAsyncParticipantsNotifier()),
          myRsvpStatusProvider
              .overrideWith(() => MockAsyncRsvpStatusNotifier()),
          roomMembershipProvider.overrideWith((a, b) => null),
          roomDisplayNameProvider.overrideWith((a, b) => 'RoomName'),
        ],
        child: const EventDetailPage(
          calendarId: '!asdf',
        ),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
}
