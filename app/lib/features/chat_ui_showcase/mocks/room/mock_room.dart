import 'package:acter/features/chat_ui_showcase/mocks/general/mock_ffi_list_ffi_string.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_ffi_string.dart';
import 'package:acter/features/chat_ui_showcase/mocks/general/mock_option_string.dart';
import 'package:acter/features/chat_ui_showcase/mocks/room/mock_member.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

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
