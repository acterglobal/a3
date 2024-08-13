import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/download_button.dart';
import 'package:acter/common/widgets/image_dialog.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/pins/actions/attachment_leading_icon.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
    this.openView = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerColor = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).colorScheme.primary;
    final attachmentType = AttachmentType.values.byName(attachment.typeStr());
    final eventId = attachment.attachmentIdStr();
    final roomId = attachment.roomIdStr();
    final mediaState = ref.watch(attachmentMediaStateProvider(attachment));

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        leading:
            mediaState.mediaLoadingState.isLoading || mediaState.isDownloading
                ? loadingIndication()
                : attachmentLeadingIcon(attachmentType),
        onTap: () => attachmentOnTap(
          ref,
          context,
          attachmentType,
          mediaState,
        ),
        onLongPress: canEdit
            ? () => openRedactContentDialog(
                  context,
                  eventId: eventId,
                  roomId: roomId,
                  title: L10n.of(context).deleteAttachment,
                  description: L10n.of(context)
                      .areYouSureYouWantToRemoveAttachmentFromPin,
                  isSpace: true,
                )
            : null,
        title: title(attachmentType),
        trailing: Visibility(
          visible: mediaState.mediaFile == null &&
              attachmentType != AttachmentType.link,
          child: IconButton(
            onPressed: () => attachmentOnTap(
              ref,
              context,
              attachmentType,
              mediaState,
            ),
            icon: const Icon(Atlas.download_arrow_down),
          ),
        ),
      ),
    );
  }

  Widget title(AttachmentType attachmentType) {
    final msgContent = attachment.msgContent();
    final fileName = msgContent.body();
    final fileNameSplit = fileName.split('.');
    final title = fileNameSplit.first;
    final fileExtension = fileNameSplit.last;
    String fileSize = getFileSize(msgContent.size() ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attachmentType == AttachmentType.link) ...[
          Text(
            attachment.name() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            attachment.link() ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ] else ...[
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Text(fileSize),
              const SizedBox(width: 10),
              const Text('.'),
              const SizedBox(width: 10),
              Text(documentTypeFromFileExtension(fileExtension)),
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
    AttachmentMediaState mediaState,
  ) async {
    // Open attachment link
    if (attachmentType == AttachmentType.link) {
      openLink(attachment.link() ?? '', context);
    }

    // If attachment is media then check media is downloaded
    else if (mediaState.mediaFile == null) {
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
                imageFile: mediaState.mediaFile!,
              );
            } else {
              return VideoDialog(
                title: msgContent.body(),
                videoFile: mediaState.mediaFile!,
              );
            }
          },
        );
      }
      // If attachment is downloaded and file or others
      else {
        if (isDesktop) {
          downloadFile(context, mediaState.mediaFile!);
        } else {
          Share.shareXFiles([XFile(mediaState.mediaFile!.path)]);
        }
      }
    }
  }

  Widget loadingIndication() {
    return const SizedBox(
      width: 40,
      height: 40,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
