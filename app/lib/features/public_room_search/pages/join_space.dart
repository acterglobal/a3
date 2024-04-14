import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/rooms.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/public_room_search/widgets/public_room_search.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JoinSpacePage extends ConsumerWidget {
  const JoinSpacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: primaryGradient),
        child: PublicRoomSearch(
          autofocus: true,
          canMatchAlias: true,
          canMatchId: true,
          onSelectedMatch: ({alias, roomId, required servers}) => onUnknown(
            context,
            ref,
            alias,
            roomId,
            servers,
          ),
          onSelected: (searchResult, searchServerName) => onSelectedKnown(
            context,
            ref,
            searchResult,
            searchServerName,
          ),
        ),
      ),
    );
  }

  void onUnknown(
    BuildContext context,
    WidgetRef ref,
    String? roomId,
    String? alias,
    List<String> serverNames,
  ) async {
    await joinRoom(
      context,
      ref,
      L10n.of(context).tryingToJoin('${alias ?? roomId}'),
      (alias ?? roomId)!,
      serverNames.first,
      (roomId) => context.pushNamed(
        Routes.space.name,
        pathParameters: {'spaceId': roomId},
      ),
    );
  }

  void onSelectedKnown(
    BuildContext context,
    WidgetRef ref,
    PublicSearchResultItem spaceSearchResult,
    String? searchServer,
  ) async {
    final roomId = spaceSearchResult.roomIdStr();
    if ((await ref.read(roomMembershipProvider(roomId).future)) != null) {
      // we know the space, user just wants to enter it
      if (spaceSearchResult.roomTypeStr() == 'Space') {
        // ignore: use_build_context_synchronously
        context.pushNamed(
          Routes.space.name,
          pathParameters: {'spaceId': roomId},
        );
      } else {
        // ignore: use_build_context_synchronously
        context.pushNamed(
          Routes.chatroom.name,
          pathParameters: {'roomId': roomId},
        );
      }
      return;
    }

    // we don't know the space yet, the user wants to join.
    final joinRule = spaceSearchResult.joinRuleStr();
    if (joinRule != 'Public') {
      // ignore: use_build_context_synchronously
      EasyLoading.showToast(L10n.of(context).joinRuleNotSupportedYet(joinRule));
      return;
    }
    // ignore: use_build_context_synchronously
    await joinRoom(
      context,
      ref,
      // ignore: use_build_context_synchronously
      L10n.of(context).tryingToJoin(spaceSearchResult.name().toString()),
      roomId,
      searchServer,
      (roomId) => context.pushNamed(
        Routes.space.name,
        pathParameters: {'spaceId': roomId},
      ),
    );
  }
}
