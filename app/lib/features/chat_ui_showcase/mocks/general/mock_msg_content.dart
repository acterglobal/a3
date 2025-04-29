import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockMsgContent extends Mock implements MsgContent {
  final String? mockBody;
  MockMsgContent({this.mockBody});

  @override
  String body() => mockBody ?? 'body';
}
