import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/rooms.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MaybeDirectRoomActionWidget extends ConsumerWidget {
  final bool canMatchAlias;
  final bool canMatchId;
  final String searchVal;
  const MaybeDirectRoomActionWidget({
    super.key,
    required this.searchVal,
    this.canMatchAlias = true,
    this.canMatchId = true,
  });

  Widget renderAliased(
    BuildContext context,
    WidgetRef ref,
    String alias,
    String server,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Card(
        child: ListTile(
          onTap: () => onSelectedMatch(context, ref, [server], alias: alias),
          title: Text(alias),
          subtitle: Text('${L10n.of(context).on} $server'),
          trailing: OutlinedButton.icon(
            onPressed: () =>
                onSelectedMatch(context, ref, [server], alias: alias),
            icon: const Icon(Atlas.entrance_thin),
            label: Text(L10n.of(context).tryToJoin),
          ),
        ),
      ),
    );
  }

  Widget renderForRoomId(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    List<String> servers,
  ) {
    final roomWatch = ref.watch(maybeRoomProvider(roomId));
    if (roomWatch.valueOrNull == null) {
      return Card(
        child: ListTile(
          onTap: () => onSelectedMatch(
            context,
            ref,
            servers,
            roomId: roomId,
          ),
          title: Text(roomId),
          subtitle: servers.isNotEmpty
              ? Text('${L10n.of(context).via} ${servers.join(', ')}')
              : null,
          trailing: OutlinedButton.icon(
            onPressed: () => onSelectedMatch(
              context,
              ref,
              servers,
              roomId: roomId,
            ),
            icon: const Icon(Atlas.entrance_thin),
            label: Text(L10n.of(context).tryToJoin),
          ),
        ),
      );
    }
    final room = roomWatch.value!;

    if (room.isJoined()) {
      if (room.isSpace()) {
        return renderSpaceCard(
          context,
          ref,
          roomId,
          onTap: () => context.pushNamed(
            Routes.space.name,
            pathParameters: {
              'spaceId': roomId,
            },
          ),
        );
      }
      return renderConvoCard(
        context,
        ref,
        roomId,
        onTap: () => context.pushNamed(
          Routes.chatroom.name,
          pathParameters: {
            'roomId': roomId,
          },
        ),
      );
    }

    final trailing = noMemberButton(context, ref, room, roomId, servers);

    if (room.isSpace()) {
      return renderSpaceCard(context, ref, roomId, trailing: trailing);
    }
    return renderConvoCard(context, ref, roomId, trailing: trailing);
  }

  Widget noMemberButton(
    BuildContext context,
    WidgetRef ref,
    Room room,
    String roomId,
    List<String> servers,
  ) {
    if (room.joinRuleStr() == 'Public') {
      return OutlinedButton(
        onPressed: () => onSelectedMatch(
          context,
          ref,
          servers,
          roomId: roomId,
        ),
        child: Text(L10n.of(context).join),
      );
    } else {
      return OutlinedButton(
        onPressed: () => onSelectedMatch(
          context,
          ref,
          servers,
          roomId: roomId,
        ),
        child: Text(L10n.of(context).requestToJoin),
      );
    }
  }

  Widget loadingCard() {
    return const Card(
      child: ListTile(
        title: Skeletonizer(child: Text('something random ...')),
        subtitle: Skeletonizer(child: Text('another random thing')),
      ),
    );
  }

  Widget renderSpaceCard(
    BuildContext context,
    WidgetRef ref,
    String roomId, {
    void Function()? onTap,
    Widget? trailing,
  }) {
    final space = ref.watch(spaceProvider(roomId)).valueOrNull;
    if (space != null) {
      return SpaceCard(
        space: space,
        showParent: true,
        onTap: onTap,
        trailing: trailing,
      );
    }
    return loadingCard();
  }

  Widget renderConvoCard(
    BuildContext context,
    WidgetRef ref,
    String roomId, {
    void Function()? onTap,
    Widget? trailing,
  }) {
    final chat = ref.watch(chatProvider(roomId)).valueOrNull;
    if (chat != null) {
      return ConvoCard(
        room: chat,
        showParent: true,
        onTap: onTap,
        trailing: trailing,
      );
    }
    return loadingCard();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aliased = aliasedHttpRegexp.firstMatch(searchVal) ??
        idAliasRegexp.firstMatch(searchVal);
    if (canMatchAlias && aliased != null) {
      final alias = aliased.namedGroup('alias')!;
      final server = aliased.namedGroup('server')!;
      return renderAliased(context, ref, alias, server);
    }

    final id = idHttpRegexp.firstMatch(searchVal) ??
        idMatrixRegexp.firstMatch(searchVal);

    if (canMatchId && id != null) {
      final roomId = id.namedGroup('id')!;
      final List<String> servers = [
        id.namedGroup('server_name') ?? '',
        id.namedGroup('server_name2') ?? '',
        id.namedGroup('server_name3') ?? '',
      ].where((e) => e.isNotEmpty).toList();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: renderForRoomId(context, ref, '!$roomId', servers),
      );
    }

    return const SizedBox.shrink();
  }

  void onSelectedMatch(
    BuildContext context,
    WidgetRef ref,
    List<String> serverNames, {
    String? roomId,
    String? alias,
  }) async {
    await joinRoom(
      context,
      ref,
      L10n.of(context).tryingToJoin('${alias ?? roomId}'),
      (alias ?? roomId)!,
      serverNames.first,
      (roomId) => context.pushNamed(
        Routes.forward.name,
        pathParameters: {'roomId': roomId},
      ),
    );
  }
}
