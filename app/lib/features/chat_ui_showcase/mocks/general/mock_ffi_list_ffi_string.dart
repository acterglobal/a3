import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockFfiListFfiString extends Mock implements FfiListFfiString {
  MockFfiListFfiString({required this.mockStrings});

  final List<FfiString> mockStrings;

  @override
  void add(FfiString value) {
    mockStrings.add(value);
  }

  List<FfiString> get strings => mockStrings;

  @override
  int get length => mockStrings.length;

  @override
  bool get isEmpty => mockStrings.isEmpty;

  @override
  FfiString operator [](int index) {
    return mockStrings[index];
  }

  // Corrected to include the growable parameter
  @override
  List<FfiString> toList({bool growable = true}) {
    return List<FfiString>.from(mockStrings, growable: growable);
  }
}
