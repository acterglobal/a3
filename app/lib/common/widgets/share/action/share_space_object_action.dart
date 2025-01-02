import 'dart:io';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/share/widgets/attach_options.dart';
import 'package:acter/common/widgets/share/widgets/external_share_options.dart';
import 'package:acter/common/widgets/share/widgets/file_share_options.dart';
import 'package:acter/features/attachments/actions/attach_ref_details.dart';
import 'package:acter/features/files/actions/download_file.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

typedef FileDetails = ({
  File file,
  String? mimeType,
});

Future<void> openShareSpaceObjectDialog({
  required BuildContext context,
  RefDetails? refDetails,
  String? internalLink,
  Future<String> Function()? shareContentBuilder,
  Future<FileDetails> Function()? fileDetailContentBuilder,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => ShareSpaceObjectActionUI(
      refDetails: refDetails,
      internalLink: internalLink,
      shareContentBuilder: shareContentBuilder,
      fileDetailContentBuilder: fileDetailContentBuilder,
    ),
  );
}

class ShareSpaceObjectActionUI extends ConsumerWidget {
  final RefDetails? refDetails;
  final String? internalLink;
  final Future<String> Function()? shareContentBuilder;
  final Future<FileDetails> Function()? fileDetailContentBuilder;

  const ShareSpaceObjectActionUI({
    super.key,
    this.refDetails,
    this.internalLink,
    this.shareContentBuilder,
    this.fileDetailContentBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (refDetails != null) ...[
              attachmentOptionsUI(context, ref, refDetails!),
              SizedBox(height: 16),
            ],
            externalShareOptionsUI(context),
            SizedBox(height: 20),
            if (fileDetailContentBuilder != null)
              fileShareOptionsUI(context, fileDetailContentBuilder!),
          ],
        ),
      ),
    );
  }

  Widget attachmentOptionsUI(
    BuildContext context,
    WidgetRef ref,
    RefDetails refDetails,
  ) {
    return AttachOptions(
      onTapBoost: () async {
        if (!context.mounted) return;
        context.pushNamed(
          Routes.actionAddUpdate.name,
          queryParameters: {'spaceId': refDetails.roomIdStr()},
          extra: refDetails,
        );
        if (!context.mounted) return;
        Navigator.pop(context);
      },
      onTapPin: () async {
        if (!context.mounted) return;
        await attachRefDetailToPin(
          context: context,
          ref: ref,
          refDetails: refDetails,
        );
        if (!context.mounted) return;
        Navigator.pop(context);
      },
      onTapEvent: () async {
        if (!context.mounted) return;
        await attachRefDetailToEvent(
          context: context,
          ref: ref,
          refDetails: refDetails,
        );
        if (!context.mounted) return;
        Navigator.pop(context);
      },
      onTapTaskList: () async {
        if (!context.mounted) return;
        await attachRefDetailToTaskList(
          context: context,
          ref: ref,
          refDetails: refDetails,
        );
        if (!context.mounted) return;
        Navigator.pop(context);
      },
    );
  }

  Widget externalShareOptionsUI(BuildContext context) {
    return ExternalShareOptions(
      qrContent: internalLink,
      shareContentBuilder: shareContentBuilder,
    );
  }

  Widget fileShareOptionsUI(
    BuildContext context,
    Future<FileDetails> Function() fileDetailContentBuilder,
  ) {
    return FileShareOptions(
      onTapOpen: () async {
        final fileDetails = await fileDetailContentBuilder();
        File file = fileDetails.file;
        final result = await OpenFilex.open(file.absolute.path);
        if (result.type == ResultType.done) {
          // done, close this dialog
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      onTapSave: !Platform.isAndroid
          ? () async {
              final fileDetails = await fileDetailContentBuilder();
              File file = fileDetails.file;
              if (!context.mounted) return;
              if (await downloadFile(context, file)) {
                // done, close this dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            }
          : null,
      onTapShare: () async {
        final fileDetails = await fileDetailContentBuilder();
        File file = fileDetails.file;
        String? mimeType = fileDetails.mimeType;
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
    );
  }
}
