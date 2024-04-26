import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:convenient_test/convenient_test.dart';
import 'package:acter/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

Future<void> startFreshTestApp(String key) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await ActerSdk.resetSessionsAndClients(key);
  await app.startAppForTesting(
    ConvenientTestWrapperWidget(child: app.makeApp()),
  );
}
