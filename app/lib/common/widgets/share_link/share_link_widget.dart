import 'package:acter/common/widgets/share_link/action/share_link_action.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ShareLinkWidget extends StatelessWidget {
  final String link;

  const ShareLinkWidget({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: PhosphorIcon(PhosphorIcons.shareFat()),
      onPressed: () => openShareLinkDialog(
        context: context,
        link: link,
      ),
    );
  }
}
