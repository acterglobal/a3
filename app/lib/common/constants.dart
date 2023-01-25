import 'package:flutter/foundation.dart';

const String heart = '\u{2764}';
const String faceWithTears = '\u{1F602}';
const String disappointedFace = '\u{1F625}';
const String angryFace = '\u{1F621}';
const String astonishedFace = '\u{1F632}';

class LoginScreenKeys {
  static const submitBtn = Key('login-submit-btn');
  static const usernameField = Key('login-username-txt');
  static const passwordField = Key('login-password-txt');
}

class Keys {
  // generic / home
  static const bottomBar = Key('bottom-bar');
  static const newsSectionBtn = Key('news-section-btn');
  static const sidebarBtn = Key('sidebar-btn');
  static const loginBtn = Key('login-btn');
  static const usernameLabel = Key('username-lbl');
}

const defaultDomain = String.fromEnvironment(
  'DEFAULT_EFFEKTIO_DOMAIN',
  defaultValue: 'effektio.org',
);
