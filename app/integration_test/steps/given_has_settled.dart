import 'package:gherkin/gherkin.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';

StepDefinitionGeneric givenWellKnownUserIsLoggedIn() {
  return given<FlutterWorld>(r'App has settled', (context) async {
    await context.world.appDriver.waitForAppToSettle();
  });
}
