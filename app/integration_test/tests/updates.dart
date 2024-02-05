import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/setup.dart';
import '../support/spaces.dart';

extension ActerNews on ConvenientTest {
  Future<void> createTextNews(String spaceId, String text) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final updatesKey = find.byKey(MainNavKeys.updates);
    await updatesKey.should(findsOneWidget);
    await updatesKey.tap();

    final newsCreateUpdatesKey = find.byKey(NewsUpdateKeys.addNewsUpdate);
    await newsCreateUpdatesKey.should(findsOneWidget);
    await newsCreateUpdatesKey.tap();

    final addTextSlideKey = find.byKey(NewsUpdateKeys.addTextSlide);
    await addTextSlideKey.should(findsOneWidget);
    await addTextSlideKey.tap();

    final slideBackgroundColorKey =
        find.byKey(NewsUpdateKeys.slideBackgroundColor);
    await slideBackgroundColorKey.should(findsOneWidget);
    await slideBackgroundColorKey.tap();

    final updateSlideTextField = find.byKey(NewsUpdateKeys.textSlideInputField);
    await updateSlideTextField.should(findsOneWidget);
    await updateSlideTextField.enterTextWithoutReplace(text);

    await slideBackgroundColorKey.tap();

    await selectSpace(spaceId, NewsUpdateKeys.selectSpace);

    final submit = find.byKey(NewsUpdateKeys.newsSubmitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }
}

void updateTests() {
  acterTestWidget('Simple Text Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    await t.createTextNews(spaceId, 'Welcome to the show');

    // we expect to be thrown to the news screen and see our latest item first:
    final textUpdateContent = find.byKey(NewsUpdateKeys.textUpdateContent);
    await textUpdateContent.should(findsOneWidget);
    await find.text('Welcome to the show').should(findsWidgets);
  });
}
