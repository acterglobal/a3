import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Home: Spaces Section Tests', () {
    testWidgets('Empty renders fine', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          spacesProvider.overrideWith(() => MockSpaceListNotifiers([])),
          bookmarkedSpacesProvider.overrideWith((a) => []),
        ],
        child: const MySpacesSection(),
      );
      expect(find.byKey(joinExistingSpaceKey), findsOneWidget);
    });
  });
}
