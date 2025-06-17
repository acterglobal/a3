import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::activities::widgets::creation');

class ActivityCreationItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityCreationItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    final roomId = activity.roomIdStr();
    final senderId = activity.senderIdStr();
    final myId = ref.watch(myUserIdStrProvider);
    final firstName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull;
    final senderName = firstName ?? simplifyUserId(senderId) ?? senderId;

    final stateMsg = getMessage(lang, myId == senderId, senderName);

    return ActivityUserCentricItemContainerWidget(
      actionIcon: Icons.add_circle_outline,
      actionTitle: L10n.of(context).creation,
      activityObject: activity.object(),
      userId: senderId,
      roomId: roomId,
      subtitle: getSubtitle(context, stateMsg),
      originServerTs: activity.originServerTs(),
    );
  }

  String? getMessage(L10n lang, bool isMe, String senderName) {
    final obj = activity.object();
    if (obj == null) {
      _log.severe('failed to get object of creation');
      return null;
    }
    if (isMe) {
      return lang.activityObjectYouCreated(obj.typeStr());
    } else {
      return lang.activityObjectOtherCreated(senderName, obj.typeStr());
    }
  }

  Widget? getSubtitle(BuildContext context, String? stateMsg) {
    if (stateMsg == null) return null;
    return Text(
      stateMsg,
      style: Theme.of(context).textTheme.labelMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
