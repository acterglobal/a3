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
  group('Event List Error Pages', () {
    testWidgets('full list', (tester) async {
      bool shouldFail = true;
      await tester.pumpProviderWidget(
        overrides: [
          eventListSearchedAndFilterProvider.overrideWith((a, b) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Space not loaded';
            }
            return [];
          }),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const EventListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
    testWidgets('full list with search', (tester) async {
      bool shouldFail = true;

      await tester.pumpProviderWidget(
        overrides: [
          searchValueProvider
              .overrideWith((_) => 'some string'), // set a search string

          eventListSearchedAndFilterProvider.overrideWith((a, b) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Space not loaded';
            }
            return [];
          }),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const EventListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });

    testWidgets('space list', (tester) async {
      bool shouldFail = true;
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
          roomMembershipProvider.overrideWith((a, b) => null),
          eventListSearchedAndFilterProvider.overrideWith((a, b) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Space not loaded';
            }
            return [];
          }),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const EventListPage(
          spaceId: '!test',
        ),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });

    testWidgets('space list with search', (tester) async {
      bool shouldFail = true;
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
          roomMembershipProvider.overrideWith((a, b) => null),
          searchValueProvider
              .overrideWith((_) => 'some search'), // set a search string
          eventListSearchedAndFilterProvider.overrideWith((a, b) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Space not loaded';
            }
            return [];
          }),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const EventListPage(
          spaceId: '!test',
        ),
      );
      await tester.ensureErrorPageWithRetryWorks();
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
