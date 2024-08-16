import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/image_dialog.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/files/actions/file_share.dart';
import 'package:acter/features/pins/actions/attachment_leading_icon.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final attachmentType = AttachmentType.values.byName(attachment.typeStr());
    final eventId = attachment.attachmentIdStr();
    final roomId = attachment.roomIdStr();
    final mediaState = ref.watch(attachmentMediaStateProvider(attachment));

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: greyColor),
      ),
      child: ListTile(
        leading: attachmentLeadingIcon(attachmentType),
        onTap: () => attachmentOnTap(
          ref,
          context,
          attachmentType,
          mediaState,
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
                      onPressed: () => ref
                          .read(
                            attachmentMediaStateProvider(attachment).notifier,
                          )
                          .downloadMedia(),
                      icon: Icon(
                        Icons.download,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
            if (canEdit)
              PopupMenuButton<String>(
                key: const Key('attachment-item-menu-options'),
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) {
                  List<PopupMenuEntry<String>> actions = [];
                  actions.add(
                    PopupMenuItem<String>(
                      key: const Key('attachment-edit'),
                      onTap: () {
                        EasyLoading.showToast(
                          L10n.of(context).comingSoon,
                          duration: const Duration(seconds: 3),
                        );
                      },
                      child: Text(L10n.of(context).edit),
                    ),
                  );
                  actions.add(
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
                  );

                  return actions;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget title(BuildContext context, AttachmentType attachmentType) {
    final msgContent = attachment.msgContent();
    final fileName = msgContent.body();
    final fileNameSplit = fileName.split('.');
    final title = attachment.name().toString();
    final fileExtension = fileNameSplit.last;
    String fileSize = getHumanReadableFileSize(msgContent.size() ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attachmentType == AttachmentType.link) ...[
          if (attachment.name() != null && attachment.name()!.isNotEmpty)
            Text(
              attachment.name()!,
              maxLines: 1,
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
    AttachmentMediaState mediaState,
  ) async {
    // Open attachment link
    if (attachmentType == AttachmentType.link) {
      openLink(attachment.link() ?? '', context);
    } else if (mediaState.mediaFile == null) {
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
        openFileShareDialog(context: context, file: mediaState.mediaFile!);
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
