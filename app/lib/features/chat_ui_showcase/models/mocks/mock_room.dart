import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockOptionString extends Mock implements OptionString {
  final String? mockText;

  MockOptionString({this.mockText});

  @override
  String? text() => mockText;
}

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

class MockFfiString extends Mock implements FfiString {
  final String value;

  MockFfiString(this.value);

  @override
  String toDartString() => value;

  @override
  String toString() => value;
}

class MockRoom extends Mock implements Room {
  final String mockRoomId;
  final String mockDisplayName;
  final String mockNotificationMode;
  final List<String>? mockActiveMembersIds;

  MockRoom({
    required this.mockRoomId,
    required this.mockDisplayName,
    this.mockNotificationMode = 'default',
    this.mockActiveMembersIds,
  });

  @override
  String roomIdStr() => mockRoomId;

  @override
  Future<OptionString> displayName() =>
      Future.value(MockOptionString(mockText: mockDisplayName));

  @override
  Future<String> notificationMode() => Future.value(mockNotificationMode);

  @override
  Future<FfiListFfiString> activeMembersIds() => Future.value(
    MockFfiListFfiString(
      mockStrings:
          mockActiveMembersIds?.map((e) => MockFfiString(e)).toList() ?? [],
    ),
  );
}
