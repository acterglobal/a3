import 'package:acter/common/extensions/options.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_init_to_null
FlutterExceptionHandler? originalOnError = null;

// allows us to disable RenderFlex overflow errors.
// by https://stackoverflow.com/questions/57499131/how-to-deactivate-or-ignore-layout-overflow-messages-in-flutter-widget-tests
void _disableOverflowErrors() {
  if (originalOnError != null) {
    return; // do not recursively do this, once is enough.
  }
  // Avoid tripping up on
  //   Actual: FlutterError:<A RenderFlex overflowed by X pixels on the bottom.>
  // #0      fail (package:matcher/src/expect/expect.dart:149:31)
  //    ....
  //
  originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exception = details.exception;
    final isOverflowError = exception is FlutterError &&
        !exception.diagnostics.any(
          (e) => e.value.toString().startsWith('A RenderFlex overflowed by'),
        );

    if (isOverflowError) {
      debugPrint('$details');
    } else {
      originalOnError.map(
        (cb) => cb(details),
        orElse: () => FlutterError.presentError(details),
      );
    }
  };
}

void _resetDisableOverflowErrors() {
  if (originalOnError != null) {
    FlutterError.onError = originalOnError;
    originalOnError = null;
  }
}

void acterTestWidget(
  // ... forward the arguments ...
  String description,
  TWidgetTesterCallback actualTest, {
  bool skip = false,
  bool settle = true,
  Timeout? timeout,
}) {
  tTestWidgets(description, (t) async {
    _disableOverflowErrors();
    try {
      await actualTest(t);
    } finally {
      // reset regardless
      _resetDisableOverflowErrors();
    }
  });
}
