import 'package:acter/common/widgets/share_link/widgets/attach_options.dart';
import 'package:acter/common/widgets/share_link/widgets/external_share_options.dart';
import 'package:flutter/material.dart';

Future<void> openShareLinkDialog({
  required BuildContext context,
  required String link,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => ShareActionUI(link: link),
  );
}

class ShareActionUI extends StatelessWidget {
  final String link;

  const ShareActionUI({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AttachOptions(
              link: link,
              isShowPinOption: false,
              isShowEventOption: false,
              isShowTaskListOption: false,
              isShowTaskOption: false,
            ),
            SizedBox(height: 16),
            ExternalShareOptions(link: link),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
