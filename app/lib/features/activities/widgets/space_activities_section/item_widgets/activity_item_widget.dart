import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/attachment.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/comment.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/reaction.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/references.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityType = activity.typeStr();
    final pushStyle = PushStyles.values.asNameMap()[activityType];
    switch (pushStyle) {
      case PushStyles.comment:
        return ActivityCommentItemWidget(activity: activity);
      case PushStyles.reaction:
        return ActivityReactionItemWidget(activity: activity);
      case PushStyles.attachment:
        return ActivityAttachmentItemWidget(activity: activity);
      case PushStyles.references:
        return ActivityReferencesItemWidget(activity: activity);
      default:
        return const SizedBox.shrink();
    }
  }
}
