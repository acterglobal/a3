import 'dart:async';
import 'package:acter/features/pins/providers/notifiers/pins_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class RetryMockAsyncPinListNotifier
    extends FamilyAsyncNotifier<List<ActerPin>, String?>
    with Mock
    implements AsyncPinListNotifier {
  bool shouldFail = true;

  @override
  Future<List<ActerPin>> build(String? arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail';
    }

    return [];
  }
}

class RetryMockAsyncPinNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActerPin, String>
    with Mock
    implements AsyncPinNotifier {
  bool shouldFail = true;

  @override
  Future<ActerPin> build(String arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail';
    }
    return MockActerPin();
  }
}

class MockActerPin extends Fake implements ActerPin {
  @override
  String roomIdStr() => '!roomId';

  @override
  String eventIdStr() => '\$evtId';

  @override
  String title() => 'Pin Title';

  @override
  Future<AttachmentsManager> attachments() =>
      Completer<AttachmentsManager>().future;

  @override
  Future<CommentsManager> comments() => Completer<CommentsManager>().future;

  @override
  MsgContent? content() => null;

  @override
  Display? display() => null;
}
