import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_bigger_visual_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::activities::widgets::room_topic_change');

class ActivityRoomTopicItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityRoomTopicItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final userId = activity.senderIdStr();
    return ActivityBiggerVisualContainerWidget(
      userId: userId,
      roomId: activity.roomIdStr(),
      actionTitle: getMessage(lang, userId) ?? '',
      target: '',
      actionIcon: PhosphorIconsRegular.pencilSimpleLine,
      subtitle: getSubtitle(context, activity.roomTopic()),
      originServerTs: activity.originServerTs(),
      leadingWidget: Icon(PhosphorIconsRegular.pencilSimpleLine, size: 25),
    );
  }

  String? getMessage(L10n lang, String senderName) {
    final content = activity.roomTopicContent();
    if (content == null) {
      _log.severe('failed to get content of room topic change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
       return lang.updateDesc;
      case 'Set':
         return lang.setDesc;
    }
    return null;
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
