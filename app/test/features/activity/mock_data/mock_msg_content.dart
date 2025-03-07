import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockMsgContent extends Mock implements MsgContent {
  final String? mockBody;
  final String? mockFormattedBody;

  MockMsgContent({required this.mockBody, this.mockFormattedBody});

  @override
  String body() => mockBody ?? 'message body';

  @override
  String? formattedBody() => mockFormattedBody;
}
