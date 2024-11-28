import 'dart:io';
import 'package:acter/common/widgets/Share/options/attach_options.dart';
import 'package:acter/common/widgets/Share/options/share_file_options.dart';
import 'package:acter/common/widgets/Share/options/external_share_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<void> openShareDialog({
  required BuildContext context,
  String? data,
  File? file,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => ShareActionUI(
      data: data,
      file: file,
    ),
  );
}

class ShareActionUI extends StatelessWidget {
  final String? data;
  final File? file;

  const ShareActionUI({super.key, this.data, this.file});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (data == null && file == null)
              Text(lang.nothingToShare, textAlign: TextAlign.center),
            if (data != null) ...[
              AttachOptions(data: data!),
              SizedBox(height: 16),
              ExternalShareOptions(data: data!),
              SizedBox(height: 16),
            ],
            if (file != null) ShareFileOptions(file: file!),
          ],
        ),
      ),
    );
  }
}
