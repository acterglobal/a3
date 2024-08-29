import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_wrapper_widget.dart';

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

  Future<void> pumpProviderScopeOnce({
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    final ProviderScope scope = widget(find.byType(ProviderScope));
    await pumpWidget(scope, duration: duration);
  }

  Future<void> pumpUntilMatches(
    Finder finder,
    Matcher matcher, {
    Duration duration = const Duration(milliseconds: 100),
    int tries = 10,
    dumpOnError = true,
  }) async {
    for (var i = 1; i <= tries; i++) {
      await pump(duration);
      if (!matcher.matches(finder, {}) && (i == tries)) {
        if (dumpOnError) {
          debugDumpApp();
          expect(finder, matches);
        }
      }
    }
  }
}

extension ActerProviderTesting on WidgetTester {
  Future<void> pumpProviderWidget({
    List<Override>? overrides,
    required Widget child,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides ?? [],
        child: InActerContextTestWrapper(
          child: child,
        ),
      ),
    );
  }
}
