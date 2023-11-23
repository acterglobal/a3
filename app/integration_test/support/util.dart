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
}
