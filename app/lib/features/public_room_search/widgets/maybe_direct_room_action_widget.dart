import 'package:acter/common/utils/rooms.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// FIXME: add matrix://-support:
// https://spec.matrix.org/v1.10/appendices/#matrix-uri-scheme

final aliasedHttpRegexp =
    RegExp(r'https://matrix.to/#/(?<alias>#.+):(?<server>.+)');

final idHttpRegexp = RegExp(
  r'https://matrix.to/#/(?<id>![^?]+)(\?via=(?<server_name>[^&]+))?(&via=(?<server_name2>[^&]+))?(&via=(?<server_name3>[^&]+))?',
);

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aliased = aliasedHttpRegexp.firstMatch(searchVal);
    if (canMatchAlias && aliased != null) {
      final alias = aliased.namedGroup('alias')!;
      final server = aliased.namedGroup('server')!;
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

    final id = idHttpRegexp.firstMatch(searchVal);
    if (canMatchId && id != null) {
      final targetId = id.namedGroup('id')!;
      final List<String> servers = [
        id.namedGroup('server_name') ?? '',
        id.namedGroup('server_name2') ?? '',
        id.namedGroup('server_name3') ?? '',
      ].where((e) => e.isNotEmpty).toList();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Card(
          child: ListTile(
            onTap: () => onSelectedMatch(
              context,
              ref,
              servers,
              roomId: targetId,
            ),
            title: Text(targetId),
            subtitle: servers.isNotEmpty
                ? Text('${L10n.of(context).via} ${servers.join(', ')}')
                : null,
            trailing: OutlinedButton.icon(
              onPressed: () => onSelectedMatch(
                context,
                ref,
                servers,
                roomId: targetId,
              ),
              icon: const Icon(Atlas.entrance_thin),
              label: Text(L10n.of(context).tryToJoin),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 0);
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
