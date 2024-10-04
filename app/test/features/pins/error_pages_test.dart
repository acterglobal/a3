import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/pins/pages/pin_details_page.dart';
import 'package:acter/features/pins/pages/pins_list_page.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/error_helpers.dart';
import '../../helpers/mock_pins_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Pin List Error Pages', () {
    testWidgets('full list', (tester) async {
      final mockedPinListNotifier = RetryMockAsyncPinListNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          pinListProvider.overrideWith(() => mockedPinListNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const PinsListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
    testWidgets('full list with search', (tester) async {
      bool shouldFail = true;

      await tester.pumpProviderWidget(
        overrides: [
          searchValueProvider
              .overrideWith((_) => 'some string'), // set a search string
          pinListSearchProvider.overrideWith((_, params) async {
            if (shouldFail) {
              shouldFail = false;
              throw 'Some Error';
            } else {
              return [];
            }
          }),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const PinsListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });

    testWidgets('space list', (tester) async {
      final mockedPinListNotifier = RetryMockAsyncPinListNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
          pinListProvider.overrideWith(() => mockedPinListNotifier),
          roomMembershipProvider.overrideWith((a, b) => null),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const PinsListPage(
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
              .overrideWith((_) => 'some other string'), // set a search string
          pinListSearchProvider.overrideWith((_, params) async {
            if (shouldFail) {
              shouldFail = false;
              throw 'Some Error';
            } else {
              return [];
            }
          }),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const PinsListPage(spaceId: '!something'),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });

  group('Pin Details Error Page', () {
    testWidgets('shows error and retries', (tester) async {
      final mockedPinNotifier = RetryMockAsyncPinNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => 'no name'),
          roomMembershipProvider.overrideWith((a, b) => null),
          canRedactProvider.overrideWith((a, b) => false),
          pinProvider.overrideWith(() => mockedPinNotifier),
        ],
        child: const PinDetailsPage(pinId: 'pinId'),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
}
