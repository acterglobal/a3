import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockConvo extends Mock implements Convo {
  final String? _mockConvoId;

  MockConvo(this._mockConvoId);

  @override
  String getRoomIdStr() => _mockConvoId ?? 'convo-id';
}
