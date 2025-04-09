import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockConvo extends Mock implements Convo {
  final String mockConvoId;

  MockConvo({required this.mockConvoId});

  @override
  String getRoomIdStr() => mockConvoId;
}
