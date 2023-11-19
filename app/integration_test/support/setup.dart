import 'package:flutter/material.dart';

bool _patched = false;

// allows us to disable RenderFlex overflow errors.
// by https://stackoverflow.com/questions/57499131/how-to-deactivate-or-ignore-layout-overflow-messages-in-flutter-widget-tests
void disableOverflowErrors() {
  if (_patched) {
    return; // do not recursively do this, once is enough.
  }
  _patched = true;
  // Avoid tripping up on
  //   Actual: FlutterError:<A RenderFlex overflowed by X pixels on the bottom.>
  // #0      fail (package:matcher/src/expect/expect.dart:149:31)
  //    ....
  //
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exception = details.exception;
    final isOverflowError = exception is FlutterError &&
        !exception.diagnostics.any(
          (e) => e.value.toString().startsWith('A RenderFlex overflowed by'),
        );

    if (isOverflowError) {
      debugPrint('$details');
    } else {
      if (originalOnError != null) {
        originalOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    }
  };
}
