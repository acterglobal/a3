// ignore_for_file: avoid_print

import '../support/login.dart';
import '../support/setup.dart';

void smokeTests() {
  acterTestWidget('register and login test smoketest', (t) async {
    final userId = await t.freshAccount();
    await t.logout();
    await t.login(userId);
  });
}
