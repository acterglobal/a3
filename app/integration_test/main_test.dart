import 'package:acter/router/router.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/appstart.dart';
import 'tests/attachments.dart';
import 'tests/auth.dart';
import 'tests/events.dart';
import 'tests/pins.dart';
import 'tests/bug_reporter.dart';
import 'tests/smoke.dart';
import 'tests/sub_spaces.dart';
import 'tests/super_invites.dart';
import 'tests/tasks.dart';
import 'tests/updates.dart';

void main() {
  convenientTestMain(ActerConvenientTestSlot(), () {
    // Minimal
    group('Smoke', smokeTests);

    // Regular infrastructure
    group('Auth', authTests);
    group('Subspace', subSpaceTests);
    group('SuperInvites', superInvitesTests);

    // specific unique features
    group('Updates', updateTests);
    group('Events', eventsTests);
    group('Tasks', tasksTests);
    group('Pins', pinsTests);
    group('Attachments', attachmentTests);

    // further infrastructure

    group('Bug Reporting', bugReporterTests);
  });
}

class ActerConvenientTestSlot extends ConvenientTestSlot {
  @override
  Future<void> appMain(AppMainExecuteMode mode) async =>
      startFreshTestApp('test-example');

  @override
  BuildContext? getNavContext(ConvenientTest t) => rootNavKey.currentContext;
}
