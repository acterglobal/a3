import 'package:acter/config/env.g.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
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
  static const forgotPassBtn = Key('forgot-pass-btn');
  static const usernameField = Key('login-username-txt');
  static const passwordField = Key('login-password-txt');
}

class Keys {
  static const mainNav = Key('main-nav'); // either bottom or sidebar
  // generic / home
  static const bottomBar = Key('bottom-bar');
  static const exploreBtn = Key('explore-btn');
  static const loginBtn = Key('login-btn');
  static const avatar = Key('user-avatar');
}

const canGuestLogin = Env.canLoginAsGuest;

const autoGuestLogin = Env.autoLoginAsGuest;

const inCI = Env.isCI;
const isDemo = Env.isDemo;
const isNightly = Env.isNightly;
const includeChatShowcase = isNightly || isDevBuild;

final defaultServers = parseServers(Env.defaultSearchServers);

const List<TargetPlatform> desktopPlatforms = [
  TargetPlatform.macOS,
  TargetPlatform.linux,
  TargetPlatform.windows,
];

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
