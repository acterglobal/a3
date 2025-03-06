import 'dart:io';

import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/image_dialog.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/files/actions/file_share.dart';
import 'package:acter/features/pins/actions/attachment_leading_icon.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Attachment, MsgContent;
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

// Attachment item UI
class MsgContentAttachmentItem extends ConsumerWidget {
  final Attachment attachment;
  final bool canEdit;

  const MsgContentAttachmentItem({
    super.key,
    required this.attachment,
    this.canEdit = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    final msgContent = attachment.msgContent();
    if (msgContent == null) return SizedBox.shrink();

    final containerColor = Theme.of(context).colorScheme.surface;
    final attachmentType = AttachmentType.values.byName(attachment.typeStr());
    final eventId = attachment.attachmentIdStr();
    final roomId = attachment.roomIdStr();
    final mediaState = ref.watch(attachmentMediaStateProvider(attachment));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).unselectedWidgetColor),
      ),
      child: ListTile(
        leading: attachmentLeadingIcon(attachmentType),
        onTap:
            () => attachmentOnTap(
              ref,
              context,
              attachmentType,
              mediaState.mediaFile,
              msgContent,
            ),
        title: title(context, attachmentType, msgContent),
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
                itemBuilder:
                    (context) => [
                      PopupMenuItem<String>(
                        key: const Key('attachment-delete'),
                        onTap: () {
                          openRedactContentDialog(
                            context,
                            eventId: eventId,
                            roomId: roomId,
                            title: lang.deleteAttachment,
                            description:
                                lang.areYouSureYouWantToRemoveAttachmentFromPin,
                            isSpace: true,
                          );
                        },
                        child: Text(
                          lang.delete,
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

  Widget title(
    BuildContext context,
    AttachmentType attachmentType,
    MsgContent msgContent,
  ) {
    final fileName = msgContent.body();
    final title = attachment.name() ?? fileName;
    final fileExtension = p.extension(fileName);
    String fileSize = getHumanReadableFileSize(msgContent.size() ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attachmentType == AttachmentType.link) ...[
          if (title.isNotEmpty)
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(
            attachment.link() ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ] else ...[
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          Row(
            children: [
              Text(fileSize, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(width: 10),
              Text('.', style: Theme.of(context).textTheme.labelMedium),
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
    MsgContent msgContent,
  ) async {
    // Open attachment link
    if (attachmentType == AttachmentType.link) {
      await openLink(ref, attachment.link() ?? '', context);
    } else if (mediaFile == null) {
      // If attachment is media then check media is downloaded
      // If attachment not downloaded
      final notifier = ref.read(
        attachmentMediaStateProvider(attachment).notifier,
      );
      await notifier.downloadMedia();
    } else {
      // If attachment is downloaded and image or video
      if (attachmentType == AttachmentType.image ||
          attachmentType == AttachmentType.video) {
        await showAdaptiveDialog(
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
        await openFileShareDialog(context: context, file: mediaFile);
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
