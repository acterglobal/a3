import 'dart:async';
import 'package:acter/features/pins/providers/notifiers/pins_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockAsyncPinNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActerPin, String>
    with Mock
    implements AsyncPinNotifier {
  bool shouldFail;

  MockAsyncPinNotifier({this.shouldFail = true});

  @override
  Future<ActerPin> build(String arg) async {
    if (shouldFail) {
      // toggle failure so the retry works
      shouldFail = !shouldFail;
      throw 'Expected fail: Space not loaded';
    }
    return FakeActerPin();
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
    return FakeActerPin();
  }
}

class MockActerPin extends Mock implements ActerPin {}

class FakeActerPin extends Fake implements ActerPin {
  final String roomId;
  final String eventId;
  final String pinTitle;

  FakeActerPin({
    this.roomId = '!roomId',
    this.eventId = 'evtId',
    this.pinTitle = 'Pin Title',
  });

  @override
  String roomIdStr() => roomId;

  @override
  String eventIdStr() => eventId;

  @override
  String title() => pinTitle;

  @override
  Future<AttachmentsManager> attachments() =>
      Completer<AttachmentsManager>().future;

  @override
  Future<CommentsManager> comments() => Completer<CommentsManager>().future;

  @override
  MsgContent? content() => null;

  @override
  Display? display() => null;

  @override
  String url() => 'https://acter.global';
}
