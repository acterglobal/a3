import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/attachment.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/comment.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/eventDateChange.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/invitationAccepted.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/invited.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/joined.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/reaction.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/references.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomAvatar.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomName.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/roomTopic.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpMaybe.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpNo.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/rsvpYes.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskAccepted.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskAdd.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskComplete.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskDecline.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskDueDateChange.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskReOpen.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/invitationRevoked.dart';

class ActivityItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityType = activity.typeStr();
    final pushStyle = PushStyles.values.asNameMap()[activityType];
    return switch (pushStyle) {
      PushStyles.comment => ActivityCommentItemWidget(activity: activity),
      PushStyles.reaction => ActivityReactionItemWidget(activity: activity),
      PushStyles.attachment => ActivityAttachmentItemWidget(activity: activity),
      PushStyles.references => ActivityReferencesItemWidget(activity: activity),
      PushStyles.eventDateChange => ActivityEventDateChangeItemWidget(activity: activity),
      PushStyles.rsvpYes => ActivityEventRSVPYesItemWidget(activity: activity),
      PushStyles.rsvpMaybe => ActivityEventRSVPMayBeItemWidget(activity: activity),
      PushStyles.rsvpNo => ActivityEventRSVPNoItemWidget(activity: activity),
      PushStyles.taskAdd => ActivityTaskAddItemWidget(activity: activity),
      PushStyles.taskComplete => ActivityTaskCompleteItemWidget(activity: activity),
      PushStyles.taskReOpen => ActivityTaskReOpenItemWidget(activity: activity),
      PushStyles.taskAccept => ActivityTaskAcceptedItemWidget(activity: activity),
      PushStyles.taskDecline => ActivityTaskDeclineItemWidget(activity: activity),
      PushStyles.taskDueDateChange => ActivityTaskDueDateChangedItemWidget(activity: activity),
      PushStyles.roomName => ActivityRoomNameItemWidget(activity: activity),
      PushStyles.roomTopic => ActivityRoomTopicItemWidget(activity: activity),
      PushStyles.roomAvatar => ActivityRoomAvatarItemWidget(activity: activity),
      PushStyles.invitationRevoked => ActivityInvitationRevokedItemWidget(activity: activity),
      PushStyles.invitationAccepted => ActivityInvitationAcceptedItemWidget(activity: activity),
      PushStyles.joined => ActivityJoinedItemWidget(activity: activity),
      PushStyles.invited => ActivityInvitedItemWidget(activity: activity),
      _ => const SizedBox.shrink(),
    };
  }
}
