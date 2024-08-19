import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpUntilFound on WidgetTester {
  Future<void> pumpProviderScope({
    int times = 10,
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    final ProviderScope scope = widget(find.byType(ProviderScope));
    for (var i = 1; i <= times; i++) {
      await pumpWidget(scope, duration: duration);
    }
  }

  Future<void> pumpUntilMatches(
    Finder finder,
    Matcher matcher, {
    Duration duration = const Duration(milliseconds: 100),
    int tries = 10,
  }) async {
    for (var i = 1; i <= tries; i++) {
      await pump(duration);
      print('$i');

      try {
        expect(finder, matches);
        break;
      } on TestFailure {
        if (i == tries) {
          debugDumpApp();
          rethrow;
        }
      }
    }
  }
}
