import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/setup.dart';
import '../support/spaces.dart';

extension ActerNews on ConvenientTest {
  Future<void> createTextNews(String spaceId, String text) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final spacesKey = find.byKey(QuickJumpKeys.createUpdateAction);
    await spacesKey.should(findsOneWidget);
    await spacesKey.tap();

    final updateField = find.byKey(NewsUpdateKeys.textUpdateField);
    await updateField.should(findsOneWidget);
    await updateField.enterTextWithoutReplace(text);

    await selectSpace(spaceId);

    final submit = find.byKey(NewsUpdateKeys.submitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }
}

void updateTests() {
  tTestWidgets('Simple Text Update', (t) async {
    disableOverflowErrors();
    final spaceId = await t.freshAccountWithSpace();
    await t.createTextNews(spaceId, 'Welcome to the show');

    // we expect to be thrown to the news screen and see our latest item first:

    final textUpdateContent = find.byKey(NewsUpdateKeys.textUpdateContent);
    await textUpdateContent.should(findsOneWidget);
    await find.text('Welcome to the show').should(findsOneWidget);
  });
}
