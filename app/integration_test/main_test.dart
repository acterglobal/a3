import 'package:acter/router/router.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import './support/appstart.dart';
import './support/login.dart';

const registrationToken = String.fromEnvironment(
  'REGISTRATION_TOKEN',
  defaultValue: '',
);

void main() {
  convenientTestMain(MyConvenientTestSlot(), () {
    group('smoketests', () {
      tTestWidgets('kyra login smoke test', (t) async {
        await t.login('kyra');
      });
      tTestWidgets('registration smoke test', (t) async {
        await t.freshAccount();
      });
    });
  });
}

class MyConvenientTestSlot extends ConvenientTestSlot {
  @override
  Future<void> appMain(AppMainExecuteMode mode) async =>
      startFreshTestApp('test-example');

  @override
  BuildContext? getNavContext(ConvenientTest t) => rootNavKey.currentContext;
}
