
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_bigger_visual_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::activities::widgets::title_change');

class ActivityTitleChangeItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityTitleChangeItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    final userId = activity.senderIdStr();
     return ActivityBiggerVisualContainerWidget(
      activityObject: activity.object(),
      userId: userId,
      roomId: activity.roomIdStr(),
      actionTitle: getMessage(lang, userId) ?? '',
      target: '',
      actionIcon: PhosphorIconsRegular.pencilSimpleLine,
      subtitle: getSubtitle(context, activity.titleContent()?.newVal()),
      originServerTs: activity.originServerTs(),
      leadingWidget: Icon(PhosphorIconsRegular.pencilSimpleLine, size: 25),
    );
  }

  String? getMessage(L10n lang, String senderName) {
    final content = activity.titleContent();
    if (content == null) {
      _log.severe('failed to get content of title change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        return lang.changedTitle(activity.object()?.typeStr() ?? '');
      case 'Set':
        return lang.setTitle(activity.object()?.typeStr() ?? '');
      case 'Unset':
        return lang.unsetTitle(activity.object()?.typeStr() ?? '');
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
