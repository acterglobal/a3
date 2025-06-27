import 'package:acter/features/activities/actions/activity_item_click_action.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_bigger_visual_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityAttachmentItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityAttachmentItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    final subType = activity.subTypeStr();
    final (icon, label) = getAttachmentIconAndLabel(context, subType ?? '');
    return ActivityBiggerVisualContainerWidget(
      onTap: () => onTapActivityItem(context, activityObject),
      actionIconBgColor: Colors.blue,
      actionIconColor: Colors.white,
      actionIcon: PhosphorIconsRegular.paperclip,
      actionTitle: L10n.of(context).addedAttachmentOn,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      target: activityObject?.title() ?? '',
      subtitle: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.surfaceTint,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.surfaceTint,
            ),
          ),
        ],
      ),
      originServerTs: activity.originServerTs(),
    );
  }
}

(IconData, String) getAttachmentIconAndLabel(
  BuildContext context,
  String subType,
) => switch (subType) {
  'image' => (Icons.image_outlined, L10n.of(context).image),
  'video' => (Icons.video_file_outlined, L10n.of(context).video),
  'audio' => (Icons.audio_file_outlined, L10n.of(context).audio),
  'file' => (Icons.file_copy_outlined, L10n.of(context).file),
  'link' => (Icons.link_outlined, L10n.of(context).link),
  _ => (Icons.attachment_outlined, L10n.of(context).attachment),
};
