import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

extension ActerUtil on ConvenientTest {
  Future<void> navigateTo(List<Key> keys) async {
    for (final key in keys) {
      final nextKey = find.byKey(key);
      await tester.ensureVisible(nextKey);
      await nextKey.should(findsOneWidget);
      await nextKey.tap();
    }
  }

  Future<void> fillForm(Map<Key, String> fields, {Key? submitBtnKey}) async {
    for (final entry in fields.entries) {
      final textField = find.byKey(entry.key);
      await tester.ensureVisible(textField);
      await textField.should(findsOneWidget);
      await textField.enterTextWithoutReplace(entry.value);
    }
    if (submitBtnKey != null) {
      final submit = find.byKey(submitBtnKey);
      await tester.ensureVisible(submit);
      await submit.should(findsOneWidget);
      await submit.tap();
    }
  }
}
