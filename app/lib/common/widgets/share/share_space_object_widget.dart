import 'package:acter/common/widgets/share/action/share_space_object_action.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ShareSpaceObjectWidget extends StatelessWidget {
  final String spaceId;
  final ObjectType objectType;
  final String objectId;

  const ShareSpaceObjectWidget({
    super.key,
    required this.spaceId,
    required this.objectType,
    required this.objectId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: PhosphorIcon(PhosphorIcons.shareFat()),
      onPressed: () => openShareSpaceObjectDialog(
        context: context,
        spaceId: spaceId,
        objectType: objectType,
        objectId: objectId,
      ),
    );
  }
}
