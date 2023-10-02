import 'package:flutter/foundation.dart';

const String heart = '\u{2764}';
const String thumbsUp = '\u{1F44D}';
const String prayHands = '\u{1F64F}';
const String faceWithTears = '\u{1F602}';
const String raisedHands = '\u{1F64C}';
const String clappingHands = '\u{1F44F}';
const String disappointedFace = '\u{1F625}';
const String angryFace = '\u{1F621}';
const String astonishedFace = '\u{1F632}';

class LoginPageKeys {
  static const signUpBtn = Key('sign-up-btn');
  static const submitBtn = Key('login-submit-btn');
  static const brandIcon = Key('brand-icon');
  static const forgotPassBtn = Key('forgot-pass-btn');
  static const usernameField = Key('login-username-txt');
  static const passwordField = Key('login-password-txt');
  static const snackbarSuccess = Key('login-snackbar-success');
  static const snackbarFailed = Key('login-snackbar-failed');
}

class Keys {
  static const mainNav = Key('main-nav'); // either bottom or sidebar

  static const newsSectionBtn = Key('news-section-btn');
  static const sidebarBtn = Key('sidebar-btn');
  static const logoutBtn = Key('login-btn');
  static const skipBtn = Key('skip-btn');
  static const loginBtn = Key('login-btn');
  static const avatar = Key('user-avatar');
  static const usernameLabel = Key('username-lbl');
}

const inCI = bool.fromEnvironment(
  'CI',
  defaultValue: false,
);

const canGuestLogin = bool.fromEnvironment(
  'CAN_LOGIN_AS_GUEST',
  defaultValue: false,
);

const autoGuestLogin = bool.fromEnvironment(
  'AUTO_LOGIN_AS_GUEST',
  defaultValue: false,
);

const giphyKey = String.fromEnvironment(
  'GIPHY_KEY',
  defaultValue: 'C4dMA7Q19nqEGdpfj82T8ssbOeZIylD4',
);

const defaultServersStr = String.fromEnvironment(
  'DEFAULT_SEARCH_SERVER',
  defaultValue: 'acter.global=Acter.global,matrix.org=Matrix.org',
);

final defaultServers = parseServers(defaultServersStr);

const List<TargetPlatform> desktopPlatforms = [
  TargetPlatform.macOS,
  TargetPlatform.linux,
  TargetPlatform.windows,
];

// hide bottom nav at locations.
const List<String> hideNavLocations = ['/updates/post', '/updates/edit'];

class ServerEntry {
  final String value;
  final String? name;
  const ServerEntry({required this.value, this.name});
}

List<ServerEntry> parseServers(String listing) {
  final List<ServerEntry> found = [];
  final separated = listing.split(',');
  for (final e in separated) {
    final entries = e.split('=');
    if (entries.length == 1) {
      found.add(ServerEntry(value: entries[0]));
    } else if (entries.length == 2) {
      found.add(ServerEntry(value: entries[0], name: entries[1]));
    } else {
      continue;
    }
  }
  return found;
}
