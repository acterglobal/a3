import 'package:acter/common/widgets/share/action/share_space_object_action.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ShareSpaceObjectWidget extends StatelessWidget {
  final String link;

  const ShareSpaceObjectWidget({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: PhosphorIcon(PhosphorIcons.shareFat()),
      onPressed: () => openShareSpaceObjectDialog(
        context: context,
        link: link,
      ),
    );
  }
}
