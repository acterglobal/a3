import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityReferencesItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityReferencesItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();

    return ActivityUserCentricItemContainerWidget(
      actionIcon: PhosphorIconsRegular.link,
      actionTitle: L10n.of(context).addedReferencesOn,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: getRefObjectWidget(context),
      originServerTs: activity.originServerTs(),
    );
  }

  Widget? getRefObjectWidget(BuildContext context) {
    final refDetails = activity.refDetails();
    final refType = refDetails?.typeStr();
    switch (refType) {
      case 'pin':
        return RefObjectWidget(
          refDetails: refDetails,
          objectDefaultIcon: PhosphorIconsRegular.pushPin,
        );
      case 'calendar-event':
        return RefObjectWidget(
          refDetails: refDetails,
          objectDefaultIcon: PhosphorIconsRegular.calendar,
        );
      case 'task-list':
        return RefObjectWidget(
          refDetails: refDetails,
          objectDefaultIcon: PhosphorIconsRegular.listChecks,
        );
      case 'task':
        return RefObjectWidget(
          refDetails: refDetails,
          objectDefaultIcon: PhosphorIconsRegular.check,
        );
      default:
        return null;
    }
  }
}

class RefObjectWidget extends ConsumerWidget {
  final RefDetails? refDetails;
  final IconData? objectDefaultIcon;
  const RefObjectWidget({
    super.key,
    required this.refDetails,
    this.objectDefaultIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (refDetails == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        getRefIconWidget(context, ref),
        const SizedBox(width: 4),
        getRefTitleTextWidget(context),
      ],
    );
  }

  Widget getRefIconWidget(BuildContext context, WidgetRef ref) {
    final defaultIconWidget = Icon(
      objectDefaultIcon,
      size: 16,
      color: Theme.of(context).textTheme.labelMedium?.color,
    );

    final refObjectId = refDetails?.targetIdStr();
    if (refObjectId == null) return defaultIconWidget;

    switch (refDetails?.typeStr()) {
      case 'pin':
        final pin = ref.watch(pinProvider(refObjectId)).valueOrNull;
        return ActerIconWidget(
          iconSize: 16,
          color: convertColor(pin?.display()?.color(), iconPickerColors[0]),
          icon: ActerIcon.iconForPin(pin?.display()?.iconStr()),
        );
      case 'task-list':
        final taskList = ref.watch(taskListProvider(refObjectId)).valueOrNull;
        return ActerIconWidget(
          iconSize: 16,
          color: convertColor(
            taskList?.display()?.color(),
            iconPickerColors[0],
          ),
          icon: ActerIcon.list,
        );
      default:
        return defaultIconWidget;
    }
  }

  Widget getRefTitleTextWidget(BuildContext context) {
    final title = refDetails?.title();
    if (title == null) return const SizedBox.shrink();
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
