import 'package:flutter/rendering.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final keyboardVisibleProvider = StreamProvider<bool>((ref) async* {
  final keyboardVisibilityController = KeyboardVisibilityController();
  yield keyboardVisibilityController.isVisible;

  await for (final keyboardState in keyboardVisibilityController.onChange) {
    debugPrint('keyboard visibility changed to: $keyboardState');
    yield keyboardState;
  }
});
