import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::keyboard');

final keyboardVisibleProvider = StreamProvider<bool>((ref) async* {
  final keyboardVisibilityController = KeyboardVisibilityController();
  yield keyboardVisibilityController.isVisible;

  await for (final keyboardState in keyboardVisibilityController.onChange) {
    _log.info('keyboard visibility changed to: $keyboardState');
    yield keyboardState;
  }
});
