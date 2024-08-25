import 'dart:async';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

class MockAsyncAllTaskListsNotifier extends AsyncNotifier<List<TaskList>>
    with Mock
    implements AsyncAllTaskListsNotifier {
  bool shouldFail = true;

  @override
  Future<List<TaskList>> build() async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail';
    }

    return [];
  }
}
