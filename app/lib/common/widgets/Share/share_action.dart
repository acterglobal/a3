import 'dart:io';
import 'package:acter/common/widgets/Share/options/attach_options.dart';
import 'package:acter/common/widgets/Share/options/share_file_options.dart';
import 'package:acter/common/widgets/Share/options/external_share_options.dart';
import 'package:flutter/material.dart';

Future<void> openShareDialog({required BuildContext context}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => ShareActionUI(),
  );
}

class ShareActionUI extends StatelessWidget {
  const ShareActionUI({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AttachOptions(data: 'hello'),
            SizedBox(height: 16),
            ExternalShareOptions(data: 'hello'),
            SizedBox(height: 16),
            ShareFileOptions(file: File('path')),
          ],
        ),
      ),
    );
  }
}
