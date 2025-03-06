import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
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
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Card(
        child: ListTile(
          onTap: () => onSelectedMatch(context, ref, [server], alias: alias),
          title: Text(alias),
          subtitle: Text('${lang.on} $server'),
          trailing: OutlinedButton.icon(
            onPressed:
                () => onSelectedMatch(context, ref, [server], alias: alias),
            icon: const Icon(Atlas.entrance_thin),
            label: Text(lang.tryToJoin),
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
    final lang = L10n.of(context);
    final roomWatch = ref.watch(maybeRoomProvider(roomId));
    if (roomWatch.valueOrNull == null) {
      return Card(
        child: ListTile(
          onTap: () => onSelectedMatch(context, ref, servers, roomId: roomId),
          title: Text(roomId),
          subtitle:
              servers.isNotEmpty
                  ? Text('${lang.via} ${servers.join(', ')}')
                  : null,
          trailing: OutlinedButton.icon(
            onPressed:
                () => onSelectedMatch(context, ref, servers, roomId: roomId),
            icon: const Icon(Atlas.entrance_thin),
            label: Text(lang.tryToJoin),
          ),
        ),
      );
    }
    final room = roomWatch.value.expect(
      'could not get room from id without domain',
    );

    if (room.isJoined()) {
      return room.isSpace()
          ? renderRoomCard(
            roomId,
            onTap:
                () => context.pushNamed(
                  Routes.space.name,
                  pathParameters: {'spaceId': roomId},
                ),
          )
          : renderRoomCard(
            roomId,
            onTap:
                () => context.pushNamed(
                  Routes.chatroom.name,
                  pathParameters: {'roomId': roomId},
                ),
          );
    }

    return renderRoomCard(
      roomId,
      trailing: noMemberButton(context, ref, room, roomId, servers),
    );
  }

  Widget noMemberButton(
    BuildContext context,
    WidgetRef ref,
    Room room,
    String roomId,
    List<String> servers,
  ) {
    final lang = L10n.of(context);
    if (room.joinRuleStr() == 'Public') {
      return OutlinedButton(
        onPressed: () => onSelectedMatch(context, ref, servers, roomId: roomId),
        child: Text(lang.join),
      );
    } else {
      return OutlinedButton(
        onPressed: () => onSelectedMatch(context, ref, servers, roomId: roomId),
        child: Text(lang.requestToJoin),
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

  Widget renderRoomCard(
    String roomId, {
    void Function()? onTap,
    Widget? trailing,
  }) {
    return RoomCard(
      roomId: roomId,
      showParents: true,
      onTap: onTap,
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aliased =
        aliasedHttpRegexp.firstMatch(searchVal) ??
        idAliasRegexp.firstMatch(searchVal);
    if (canMatchAlias && aliased != null) {
      final alias = aliased
          .namedGroup('alias')
          .expect('could not extract alias from search value');
      final server = aliased
          .namedGroup('server')
          .expect('could not extract server from search value');
      return renderAliased(context, ref, alias, server);
    }

    final id =
        idHttpRegexp.firstMatch(searchVal) ??
        idMatrixRegexp.firstMatch(searchVal);

    if (canMatchId && id != null) {
      final roomId = id
          .namedGroup('id')
          .expect('could not extract id from search value');
      final List<String> servers =
          [
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

  Future<void> onSelectedMatch(
    BuildContext context,
    WidgetRef ref,
    List<String> serverNames, {
    String? roomId,
    String? alias,
  }) async {
    final roomIdOrAlias = alias ?? roomId;
    if (roomIdOrAlias == null) throw 'neither room id nor alias available';
    final newRoomId = await joinRoom(
      context: context,
      ref: ref,
      roomIdOrAlias: roomIdOrAlias,
      serverNames: serverNames,
    );
    if (newRoomId != null && context.mounted) {
      context.pushNamed(
        Routes.forward.name,
        pathParameters: {'roomId': newRoomId},
      );
    }
  }
}
