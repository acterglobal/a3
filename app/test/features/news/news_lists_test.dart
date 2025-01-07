import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/news/pages/news_list_page.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_news_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('News List', () {
    testWidgets('displays empty state when there are no news', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          newsListProvider.overrideWith(() => MockAsyncNewsListNotifier()),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const NewsListPage(),
      );

      await tester.pump();

      expect(
        find.byType(EmptyState),
        findsOneWidget,
      ); // Ensure the empty state widget is displayed
    });
  });
}
