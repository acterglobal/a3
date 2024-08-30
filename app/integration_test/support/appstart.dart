import 'package:acter/config/setup.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:convenient_test/convenient_test.dart';
import 'package:acter/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

bool hasSetup = false;

Future<void> startFreshTestApp(String key) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!hasSetup) {
    hasSetup = true;
    configSetup();
  }
  await ActerSdk.resetSessionsAndClients(key);
  await app.startAppForTesting(
    ConvenientTestWrapperWidget(child: app.makeApp()),
  );
}
