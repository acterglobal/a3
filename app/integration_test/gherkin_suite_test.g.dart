// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gherkin_suite_test.dart';

// **************************************************************************
// GherkinSuiteTestGenerator
// **************************************************************************

class _CustomGherkinIntegrationTestRunner extends GherkinIntegrationTestRunner {
  _CustomGherkinIntegrationTestRunner({
    required FlutterTestConfiguration configuration,
    required StartAppFn appMainFunction,
    required Timeout scenarioExecutionTimeout,
    AppLifecyclePumpHandlerFn? appLifecyclePumpHandler,
    LiveTestWidgetsFlutterBindingFramePolicy? framePolicy,
  }) : super(
          configuration: configuration,
          appMainFunction: appMainFunction,
          scenarioExecutionTimeout: scenarioExecutionTimeout,
          appLifecyclePumpHandler: appLifecyclePumpHandler,
          framePolicy: framePolicy,
        );

  @override
  void onRun() {
    testFeature0();
  }

  void testFeature0() {
    runFeature(
      name: 'Login Smoketest:',
      tags: <String>[],
      run: () {
        runScenario(
          name: 'After login, ensure username',
          description: null,
          path:
              'C:\\flutter-projects\\acter\\app\\.\\integration_test\\features\\login_smoketest.feature',
          tags: <String>[],
          steps: [
            (
              TestDependencies dependencies,
              bool skip,
            ) async {
              return await runStep(
                name: 'Given kyra has logged in',
                multiLineStrings: <String>[],
                table: null,
                dependencies: dependencies,
                skip: skip,
              );
            },
          ],
          onBefore: () async => onBeforeRunFeature(
            name: 'Login Smoketest',
            path:
                'C:\\flutter-projects\\acter\\app\\.\\integration_test\\features\\login_smoketest.feature',
            description: """Trying to login and ensure it works""",
            tags: <String>[],
          ),
          onAfter: () async => onAfterRunFeature(
            name: 'Login Smoketest',
            path:
                'C:\\flutter-projects\\acter\\app\\.\\integration_test\\features\\login_smoketest.feature',
            description: """Trying to login and ensure it works""",
            tags: <String>[],
          ),
        );
      },
    );
  }
}

Future<void> executeTestSuite({
  required FlutterTestConfiguration configuration,
  required StartAppFn appMainFunction,
  Timeout scenarioExecutionTimeout = const Timeout(const Duration(minutes: 10)),
  AppLifecyclePumpHandlerFn? appLifecyclePumpHandler,
  LiveTestWidgetsFlutterBindingFramePolicy? framePolicy,
}) {
  return _CustomGherkinIntegrationTestRunner(
    configuration: configuration,
    appMainFunction: appMainFunction,
    appLifecyclePumpHandler: appLifecyclePumpHandler,
    scenarioExecutionTimeout: scenarioExecutionTimeout,
    framePolicy: framePolicy,
  ).run();
}
