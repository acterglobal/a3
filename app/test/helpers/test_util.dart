import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:test_screenshot/test_screenshot.dart';

import 'mock_go_router.dart';
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
    MockNavigator? navigatorOverride,
    GoRouter? goRouter,
    String? screenshotPath,
    required Widget child,
  }) async {
    if (goRouter != null) {
      child = MockGoRouterProvider(goRouter: goRouter, child: child);
    }
    if (navigatorOverride != null) {
      child = MockNavigatorProvider(navigator: navigatorOverride, child: child);
    }
    if (screenshotPath != null) {
      await loadFonts();
    }
    await pumpWidget(
      ProviderScope(
        overrides: overrides ?? [],
        child: InActerContextTestWrapper(child: child),
      ),
    );
    if (screenshotPath != null) {
      await screenshot(path: screenshotPath);
    }
  }
}

extension SizeSetting on WidgetTester {
  Future<void> configureTesterForSize(
    Size canvasSize, [
    double devicePixelRatio = 2.75,
  ]) async {
    final convertedSize = Size(
      canvasSize.width / devicePixelRatio,
      canvasSize.height / devicePixelRatio,
    );
    await binding.setSurfaceSize(convertedSize);
    view.physicalSize = convertedSize;
    view.devicePixelRatio = 1.0;
  }
}

/// Custom finder to search for text within RichText widgets
Finder findRichTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    if (widget is RichText) {
      final plainText = widget.text.toPlainText();
      return plainText.contains(text);
    }
    return false;
  });
}
