import 'dart:io';

import 'package:acter/features/files/actions/download_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:open_filex/open_filex.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

Future<void> openFileShareDialog({
  required BuildContext context,
  required File file,
  Widget? header,
  String? mimeType,
  List<Widget>? beforeOptions,
  List<Widget>? afterOptions,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
    constraints: const BoxConstraints(maxHeight: 300),
    builder: (context) => _FileOptionsDialog(
      file: file,
      header: header,
      beforeOptions: beforeOptions,
      afterOptions: afterOptions,
      mimeType: mimeType,
    ),
  );
}

class _FileOptionsDialog extends StatelessWidget {
  final File file;
  final String? mimeType;
  final Widget? header;
  final List<Widget>? beforeOptions;
  final List<Widget>? afterOptions;

  const _FileOptionsDialog({
    required this.file,
    this.header,
    this.afterOptions,
    this.beforeOptions,
    this.mimeType,
  });

  @override
  Widget build(BuildContext context) {
    final before = beforeOptions;
    final after = afterOptions;
    final lang = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      constraints: const BoxConstraints(
        maxWidth: 600,
        minWidth: 300,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header ?? const SizedBox.shrink(),
          if (header != null) const SizedBox(height: 16.0),
          if (before != null) ...before,
          TextButton.icon(
            onPressed: () async {
              final result = await OpenFilex.open(file.absolute.path);
              if (result.type == ResultType.done) {
                // done, close this dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            label: Text(lang.openFile),
            icon: PhosphorIcon(PhosphorIcons.fileArrowUp()),
          ),
          TextButton.icon(
            onPressed: () async {
              final result = await Share.shareXFiles(
                [XFile(file.path, mimeType: mimeType)],
              );
              if (result.status == ShareResultStatus.success) {
                // done, close this dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            label: Text(lang.shareFile),
            icon: PhosphorIcon(PhosphorIcons.shareNetwork()),
          ),
          if (!Platform.isAndroid) // crashes on Android for some reason ...
            TextButton.icon(
              onPressed: () async {
                if (await downloadFile(context, file)) {
                  // done, close this dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              label: Text(lang.saveFileAs),
              icon: PhosphorIcon(PhosphorIcons.downloadSimple()),
            ),
          if (after != null) ...after,
        ],
      ),
    );
  }
}
