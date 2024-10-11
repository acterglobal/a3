import 'dart:io';

import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/image_dialog.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/files/actions/file_share.dart';
import 'package:acter/features/pins/actions/attachment_leading_icon.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

// Attachment item UI
class AttachmentItem extends ConsumerWidget {
  final Attachment attachment;
  final bool canEdit;

  // whether item can be viewed on gesture
  final bool? openView;

  const AttachmentItem({
    super.key,
    required this.attachment,
    this.canEdit = false,
    this.openView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerColor = Theme.of(context).colorScheme.surface;
    final attachmentType = AttachmentType.values.byName(attachment.typeStr());
    final eventId = attachment.attachmentIdStr();
    final roomId = attachment.roomIdStr();
    final mediaState = ref.watch(attachmentMediaStateProvider(attachment));

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).unselectedWidgetColor),
      ),
      child: ListTile(
        leading: attachmentLeadingIcon(attachmentType),
        onTap: () => attachmentOnTap(
          ref,
          context,
          attachmentType,
          mediaState.mediaFile,
        ),
        title: title(context, attachmentType),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mediaState.mediaFile == null &&
                attachmentType != AttachmentType.link)
              mediaState.mediaLoadingState.isLoading || mediaState.isDownloading
                  ? loadingIndication()
                  : IconButton(
                      onPressed: () async {
                        final notifier = ref.read(
                          attachmentMediaStateProvider(attachment).notifier,
                        );
                        await notifier.downloadMedia();
                      },
                      icon: Icon(
                        Icons.download,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
            if (canEdit)
              PopupMenuButton<String>(
                key: const Key('attachment-item-menu-options'),
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    key: const Key('attachment-delete'),
                    onTap: () {
                      openRedactContentDialog(
                        context,
                        eventId: eventId,
                        roomId: roomId,
                        title: L10n.of(context).deleteAttachment,
                        description: L10n.of(context)
                            .areYouSureYouWantToRemoveAttachmentFromPin,
                        isSpace: true,
                      );
                    },
                    child: Text(
                      L10n.of(context).delete,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget title(BuildContext context, AttachmentType attachmentType) {
    final msgContent = attachment.msgContent();
    final fileName = msgContent.body();
    final title = attachment.name() ?? fileName;
    final fileExtension = p.extension(fileName);
    String fileSize = getHumanReadableFileSize(msgContent.size() ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attachmentType == AttachmentType.link) ...[
          if (title.isNotEmpty)
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            attachment.link() ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ] else ...[
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Text(
                fileSize,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(width: 10),
              Text(
                '.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(width: 10),
              Text(
                documentTypeFromFileExtension(fileExtension),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> attachmentOnTap(
    WidgetRef ref,
    BuildContext context,
    AttachmentType attachmentType,
    File? mediaFile,
  ) async {
    // Open attachment link
    if (attachmentType == AttachmentType.link) {
      openLink(attachment.link() ?? '', context);
    } else if (mediaFile == null) {
      // If attachment is media then check media is downloaded
      // If attachment not downloaded
      ref
          .read(attachmentMediaStateProvider(attachment).notifier)
          .downloadMedia();
    } else {
      // If attachment is downloaded and image or video
      if (attachmentType == AttachmentType.image ||
          attachmentType == AttachmentType.video) {
        final msgContent = attachment.msgContent();
        showAdaptiveDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: false,
          builder: (context) {
            if (attachmentType == AttachmentType.image) {
              return ImageDialog(
                title: msgContent.body(),
                imageFile: mediaFile,
              );
            } else {
              return VideoDialog(
                title: msgContent.body(),
                videoFile: mediaFile,
              );
            }
          },
        );
      }
      // If attachment is downloaded and file or others
      else {
        openFileShareDialog(context: context, file: mediaFile);
      }
    }
  }

  Widget loadingIndication() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
