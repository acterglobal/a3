import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_bigger_visual_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::activities::widgets::description_change');

class ActivityDescriptionChangeItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityDescriptionChangeItemWidget({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    final userId = activity.senderIdStr();

    return ActivityBiggerVisualContainerWidget(
      actionIcon: PhosphorIconsThin.pencilLine,
      actionTitle: getMessage(lang, userId) ?? '',
      target: '',
      actionIconBgColor: Colors.blueGrey,
      actionIconColor: Colors.white,
      activityObject: activity.object(),
      userId: userId,
      roomId: activity.roomIdStr(),
      subtitle: getSubtitle(
        context,
        activity.descriptionContent()?.newVal().toString().trim(),
      ),
      originServerTs: activity.originServerTs(),
    );
  }

  String? getMessage(L10n lang, String senderName) {
    final content = activity.descriptionContent();
    if (content == null) {
      _log.severe('failed to get content of description change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        return lang.changedDescription(activity.object()?.typeStr() ?? '');
      case 'Set':
        return lang.setDescription(activity.object()?.typeStr() ?? '');
      case 'Unset':
        return lang.unsetDescription(activity.object()?.typeStr() ?? '');
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
