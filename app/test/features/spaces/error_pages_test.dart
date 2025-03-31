import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/space/pages/space_details_page.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/error_helpers.dart';
import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Space Details Error Page', () {
    testWidgets('shows error and retries', (tester) async {
      bool shouldFail = true;
      await tester.pumpProviderWidget(
        overrides: [
          // mocking so we can display the page in general
          roomJoinRuleProvider.overrideWith((a, b) => null),
          roomDisplayNameProvider.overrideWith((a, b) => null),
          parentAvatarInfosProvider.overrideWith((a, b) => []),
          roomAvatarProvider.overrideWith((a, b) => null),
          membersIdsProvider.overrideWith((a, b) => []),
          roomAvatarInfoProvider.overrideWith(
            () => MockRoomAvatarInfoNotifier(),
          ),
          roomMembershipProvider.overrideWith((a, b) => null),
          isBookmarkedProvider.overrideWith((a, b) => false),
          spaceInvitedMembersProvider.overrideWith((a, b) => []),
          shouldShowSuggestedProvider.overrideWith((a, b) => false),
          isActerSpace.overrideWith((a, b) => false),

          // the actual failing ones
          spaceProvider.overrideWith((a, b) {
            if (shouldFail) {
              // toggle failure so the retry works
              shouldFail = !shouldFail;
              throw 'Expected fail: Space not loaded';
            }
            return MockSpace();
          }),
          tabsProvider.overrideWith((ref, id) async {
            await ref.watch(
              spaceProvider(id).future,
            ); // let this fail internally
            return [];
          }),
        ],
        child: const SpaceDetailsPage(spaceId: '!spaceId'),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
}
