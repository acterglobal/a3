import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_space_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityRoomNameItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityRoomNameItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) { 
    final subTitle = activity.roomName() ?? '';
    return ActivitySpaceItemContainerWidget(
      actionIcon: PhosphorIconsRegular.pencilSimpleLine,   
      updatedText: L10n.of(context).spaceNameUpdate,  
       subtitle: Text( 
        subTitle, 
        style: Theme.of(context).textTheme.labelMedium,  
        maxLines: 2,
        overflow: TextOverflow.ellipsis,  
      ), 
      userId: activity.senderIdStr(),   
      roomId: activity.roomIdStr(),  
      originServerTs: activity.originServerTs(),
    );  
  }
}
