import 'package:convenient_test_dev/convenient_test_dev.dart';
import '../support/login.dart';

void updateTests() {
  tTestWidgets('Text Update', (t) async {
    final userId = await t.freshAccountWithSpace();
  });
}
