import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/public_room_search/widgets/public_room_search.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchPublicDirectory extends ConsumerWidget {
  final String? query;

  const SearchPublicDirectory({super.key, this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PublicRoomSearch(
      initialQuery: query,
      autofocus: true,
      onSelected:
          (searchResult, searchServerName) =>
              onSelectedKnown(context, ref, searchResult, searchServerName),
    );
  }

  Future<void> onSelectedKnown(
    BuildContext context,
    WidgetRef ref,
    PublicSearchResultItem spaceSearchResult,
    String? searchServer,
  ) async {
    final lang = L10n.of(context);
    final roomId = spaceSearchResult.roomIdStr();
    final membership = await ref.read(roomMembershipProvider(roomId).future);
    if (!context.mounted) return;
    if (membership != null) {
      // we know the space, user just wants to enter it
      if (spaceSearchResult.roomTypeStr() == 'Space') {
        context.pushNamed(
          Routes.space.name,
          pathParameters: {'spaceId': roomId},
        );
      } else {
        context.pushNamed(
          Routes.chatroom.name,
          pathParameters: {'roomId': roomId},
        );
      }
      return;
    }

    // we don’t know the space yet, the user wants to join.
    final joinRule = spaceSearchResult.joinRuleStr();
    if (joinRule != 'Public') {
      EasyLoading.showToast(lang.joinRuleNotSupportedYet(joinRule));
      return;
    }
    final newRoomId = await joinRoom(
      context: context,
      ref: ref,
      roomIdOrAlias: roomId,
      serverNames: searchServer != null ? [searchServer] : [],
      roomName: spaceSearchResult.name(),
    );

    if (newRoomId != null && context.mounted) {
      context.pushNamed(
        Routes.space.name,
        pathParameters: {'spaceId': newRoomId},
      );
    }
  }
}
