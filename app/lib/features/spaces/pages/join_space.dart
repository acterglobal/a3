import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/rooms.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/spaces/widgets/public_spaces_selector.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class JoinSpacePage extends ConsumerWidget {
  const JoinSpacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: primaryGradient,
        ),
        child: PublicSpaceSelector(
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
          onSelected: (searchResult, searchServerName, space) =>
              onSelectedKnown(
            context,
            ref,
            searchResult,
            searchServerName,
            space,
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
        pathParameters: {
          'spaceId': roomId,
        },
      ),
    );
  }

  void onSelectedKnown(
    BuildContext context,
    WidgetRef ref,
    PublicSearchResultItem spaceSearchResult,
    String? searchServer,
    SpaceItem? spaceInfo,
  ) async {
    if (spaceInfo != null) {
      // we know the space, user just wants to enter it
      context.pushNamed(
        Routes.space.name,
        pathParameters: {'spaceId': spaceInfo.roomId},
      );
      return;
    }

    // we don't know the space yet, the user wants to join.
    final joinRule = spaceSearchResult.joinRuleStr();
    if (joinRule != 'Public') {
      customMsgSnackbar(
        context,
        L10n.of(context).joinRuleNotSupportedYet(joinRule),
      );
      return;
    }
    await joinRoom(
      context,
      ref,
      L10n.of(context).tryingToJoin('${spaceSearchResult.name()}'),
      spaceSearchResult.roomIdStr(),
      searchServer,
      (roomId) => context.pushNamed(
        Routes.space.name,
        pathParameters: {
          'spaceId': roomId,
        },
      ),
    );
  }
}
