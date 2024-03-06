import 'dart:io';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:flutter/material.dart';

// reusable attachment confirmation dialog
void attachmentConfirmationDialog(
  BuildContext context,
  List<File>? selectedFiles,
  Widget fileWidget,
  Future<void> Function(
    List<File> files,
    AttachmentType attachmentType,
  ) handleFileUpload,
  AttachmentType attachmentType,
) async {
  if (context.mounted) {
    if (selectedFiles != null && selectedFiles.isNotEmpty) {
      String fileName = selectedFiles.first.path.split('/').last;
      showAdaptiveDialog(
        context: context,
        builder: (ctx) => DefaultDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Upload Files (${selectedFiles.length})',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          subtitle: Visibility(
            visible: selectedFiles.length <= 5,
            child: fileWidget,
          ),
          description: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(fileName, style: Theme.of(ctx).textTheme.bodySmall),
          ),
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                handleFileUpload(selectedFiles, attachmentType);
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      );
    }
  }
}
