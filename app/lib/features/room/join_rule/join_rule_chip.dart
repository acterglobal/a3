import 'package:acter/common/actions/show_limited_space_list.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::joinRule::chip');

class JoinRuleChip extends ConsumerWidget {
  final String roomId;
  final bool useCompactView;

  const JoinRuleChip({
    super.key,
    required this.roomId,
    this.useCompactView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinRuleLoader = ref.watch(roomJoinRuleProvider(roomId));
    return joinRuleLoader.when(
      data:
          (joinRule) => GestureDetector(
            onTap: () {
              if (joinRule != RoomJoinRule.Restricted) return;
              showLimitedSpaceList(context, roomId);
            },
            child: renderSpaceChip(context, joinRule),
          ),
      error: (e, s) {
        _log.severe('Failed to load room joinRule', e, s);
        return Chip(label: Text(L10n.of(context).loadingFailed(e)));
      },
      loading: () => renderLoading(),
    );
  }

  Widget renderLoading() {
    return Skeletonizer(
      child: SizedBox(
        width: 100,
        child: Chip(avatar: const Icon(Icons.language), label: Text(roomId)),
      ),
    );
  }

  Widget renderSpaceChip(BuildContext context, RoomJoinRule? joinRule) {
    final lang = L10n.of(context);
    IconData icon = switch (joinRule) {
      RoomJoinRule.Public => Icons.language,
      RoomJoinRule.Restricted => Atlas.users,
      _ => Icons.lock,
    };
    String label = switch (joinRule) {
      RoomJoinRule.Public => lang.public,
      RoomJoinRule.Restricted => lang.limited,
      _ => lang.private,
    };
    return useCompactView
        ? Text(label, style: Theme.of(context).textTheme.labelSmall)
        : Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          label: Text(label, style: Theme.of(context).textTheme.labelSmall),
        );
  }
}
