abstract class TestSuite {
  Future<void> setup();

  Stream<String> executeTest();

  Future<void> teardown();
}

enum SuiteState {
  uninitialized,
  executing,
  finished,
}
