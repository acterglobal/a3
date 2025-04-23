import 'package:acter/features/chat_ui_showcase/models/mocks/mock_convo.dart';
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

class MockMember extends Mock implements Member {
  final String mockMemberId;
  final String mockRoomId;
  final String mockMembershipStatusStr;
  final bool mockCanString;

  MockMember({
    required this.mockMemberId,
    required this.mockRoomId,
    required this.mockMembershipStatusStr,
    required this.mockCanString,
  });

  @override
  UserId userId() => MockUserId(mockUserId: mockMemberId);

  @override
  String roomIdStr() => mockRoomId;

  @override
  String membershipStatusStr() => mockMembershipStatusStr;

  @override
  bool canString(String permission) => mockCanString;
}

class MockRoom extends Mock implements Room {
  final String mockRoomId;
  final String mockDisplayName;
  final String mockNotificationMode;
  final List<String>? mockActiveMembersIds;
  final bool? mockIsJoined;

  MockRoom({
    required this.mockRoomId,
    required this.mockDisplayName,
    this.mockNotificationMode = 'default',
    this.mockActiveMembersIds,
    this.mockIsJoined,
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

  @override
  bool isJoined() => mockIsJoined ?? true;

  @override
  Future<Member> getMyMembership() =>
      mockActiveMembersIds != null
          ? Future.value(
            MockMember(
              mockMemberId: mockActiveMembersIds![0],
              mockRoomId: mockRoomId,
              mockMembershipStatusStr: 'active',
              mockCanString: true,
            ),
          )
          : Future.value(
            MockMember(
              mockMemberId: 'mock-member-id',
              mockRoomId: mockRoomId,
              mockMembershipStatusStr: 'unknown',
              mockCanString: true,
            ),
          );
}
