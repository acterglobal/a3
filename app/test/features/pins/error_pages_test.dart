import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/pins/pages/pins_list_page.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/error_helpers.dart';
import '../../helpers/mock_pins_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Pins Error Pages', () {
    testWidgets('full list', (tester) async {
      final mockedPinListNotifier = MockAsyncPinListNotifier();
      await tester.pumpProviderWidget(
        overrides: [
          pinListProvider.overrideWith(() => mockedPinListNotifier),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const PinsListPage(),
      );
      await tester.ensureErrorPageWithRetryWorks();
    });
  });
}
