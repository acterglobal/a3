import 'dart:async';
import 'package:acter/features/pins/providers/notifiers/pins_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

class MockAsyncPinListNotifier
    extends FamilyAsyncNotifier<List<ActerPin>, String?>
    with Mock
    implements AsyncPinListNotifier {
  bool shouldFail = true;

  @override
  Future<List<ActerPin>> build(String? arg) async {
    if (shouldFail) {
      shouldFail = !shouldFail;
      throw 'Expected fail';
    }

    return [];
  }
}
