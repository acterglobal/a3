import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::keyboard_visibility_provider');

final keyboardVisibleProvider = StreamProvider<bool>((ref) async* {
  final keyboardVisibilityController = KeyboardVisibilityController();
  yield keyboardVisibilityController.isVisible;

  await for (final keyboardState in keyboardVisibilityController.onChange) {
    _log.info('keyboard visibility changed to: $keyboardState');
    yield keyboardState;
  }
});
