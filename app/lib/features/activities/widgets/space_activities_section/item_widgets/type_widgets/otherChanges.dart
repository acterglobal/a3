import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::activities::widgets::other_changes');

class ActivityOtherChangesItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityOtherChangesItemWidget({super.key, required this.activity});

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
      actionIcon: PhosphorIconsRegular.pencilLine,
      actionTitle: L10n.of(context).updated,
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
      _log.severe('failed to get object of other changes');
      return null;
    }
    if (isMe) {
      return lang.activitySomethingYouChanged(obj.typeStr());
    } else {
      return lang.activitySomethingOtherChanged(senderName, obj.typeStr());
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
