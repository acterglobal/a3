import 'package:convenient_test_dev/convenient_test_dev.dart';
import '../support/login.dart';
import '../support/setup.dart';

const registrationToken = String.fromEnvironment(
  'REGISTRATION_TOKEN',
  defaultValue: '',
);

void loginTests() {
  tTestWidgets('registration smoke test', (t) async {
    disableOverflowErrors();
    await t.freshAccount();
  });
  tTestWidgets('register and login test', (t) async {
    disableOverflowErrors();
    final userId = await t.freshAccount();
    await t.logout();
    await t.login(userId);
  });
}
