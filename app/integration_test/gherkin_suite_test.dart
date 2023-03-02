import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';
import 'steps/given_login.dart';

import 'package:effektio/main.dart' as app;

part 'gherkin_suite_test.g.dart';

// ignore_for_file: avoid_print

@GherkinTestSuite(
  executionOrder: ExecutionOrder.alphabetical,
  featurePaths: <String>['integration_test/features/**.feature'],
)
Future<void> main() async {
  final steps = [
    givenWellKnownUserIsLoggedIn(),
  ];
  final config = FlutterTestConfiguration(
    features: [RegExp('features/*.*.feature')],
    reporters: [
      StdoutReporter(MessageLevel.verbose)
        ..setWriteLineFn(print)
        ..setWriteFn(print),
      ProgressReporter()
        ..setWriteLineFn(print)
        ..setWriteFn(print),
      TestRunSummaryReporter()
        ..setWriteLineFn(print)
        ..setWriteFn(print),
      TestRunSummaryReporter(),
      JsonReporter(path: './report.json'),
    ],
    hooks: [
      AttachScreenshotOnFailedStepHook(),
    ],
    stepDefinitions: steps,
    customStepParameterDefinitions: [],
  );
  await executeTestSuite(
    configuration: config,
    appMainFunction: (World world) async =>
        await app.startFreshTestApp('kyra_can_login_smoketest'),
  );
}
