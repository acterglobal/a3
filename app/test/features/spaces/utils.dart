import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/features/space/widgets/space_info.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../helpers/mock_space_providers.dart';

List<Override> spaceOverrides() => [
  // mocking so we can display the page in general
  roomVisibilityProvider.overrideWith((a, b) => null),
  roomDisplayNameProvider.overrideWith((a, b) => null),
  parentAvatarInfosProvider.overrideWith((a, b) => []),
  roomAvatarProvider.overrideWith((a, b) => null),
  membersIdsProvider.overrideWith((a, b) => []),
  roomAvatarInfoProvider.overrideWith(() => MockRoomAvatarInfoNotifier()),
  roomMembershipProvider.overrideWith((a, b) => null),
  isBookmarkedProvider.overrideWith((a, b) => false),
  spaceInvitedMembersProvider.overrideWith((a, b) => []),
  shouldShowSuggestedProvider.overrideWith((a, b) => false),
  isActerSpaceForSpace.overrideWith((a, b) => false),
  suggestedSpacesProvider.overrideWith((a, b) async {
    return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
  }),
];
