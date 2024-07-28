import 'dart:io';
import 'dart:typed_data';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/attachments/widgets/attachment_item.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Attachment, AttachmentDraft, AttachmentsManager;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::attachments');

class AttachmentSectionWidget extends ConsumerWidget {
  static const attachmentsKey = Key('attachments');
  static const redactBtnKey = Key('attachments-redact-btn');
  static const addAttachmentBtnKey = Key('attachments-add-btn');
  static const confirmRedactKey = Key('attachments-confirm-redact');
  final Future<AttachmentsManager> manager;

  const AttachmentSectionWidget({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(attachmentsManagerProvider(manager)).when(
          data: (manager) => FoundAttachmentSectionWidget(
            attachmentManager: manager,
            key: attachmentsKey,
          ),
          error: (e, st) => onError(context, e),
          loading: () => loading(context),
        );
  }

  Widget onError(BuildContext context, Object error) {
    return Column(
      children: [
        Text(L10n.of(context).attachments),
        Text(L10n.of(context).loadingFailed(error)),
      ],
    );
  }

  Widget loading(BuildContext context) {
    return const Skeletonizer(
      child: SizedBox(
        height: 100,
        width: 100,
      ),
    );
  }
}

/// Attachment Section Widget, only exposed for integration testing.
class FoundAttachmentSectionWidget extends ConsumerWidget {
  final AttachmentsManager attachmentManager;

  const FoundAttachmentSectionWidget({
    required this.attachmentManager,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentTitleTextStyle = Theme.of(context).textTheme.labelLarge;
    final attachments = ref.watch(attachmentsProvider(attachmentManager));

    bool canEdit = attachmentManager.canEditAttachments();

    return attachments.when(
      data: (list) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  const Icon(Atlas.paperclip_attachment_thin, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    L10n.of(context).attachments,
                    style: attachmentTitleTextStyle,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 5.0,
                runSpacing: 10.0,
                children: <Widget>[
                  if (list.isNotEmpty)
                    for (var item in list)
                      _buildAttachmentItem(context, item, canEdit),
                  if (canEdit) _buildAddAttachment(context, ref),
                ],
              ),
            ],
          ),
        );
      },
      error: (err, st) => Text(L10n.of(context).errorLoadingAttachments(err)),
      loading: () => const Skeletonizer(
        child: Wrap(
          spacing: 5.0,
          runSpacing: 10.0,
          children: [],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(
    BuildContext context,
    Attachment item,
    bool canEdit,
  ) {
    final eventId = item.attachmentIdStr();
    final roomId = item.roomIdStr();
    final sender = item.sender();
    return Stack(
      children: [
        AttachmentItem(
          key: Key('$eventId-attachment'),
          attachment: item,
        ),
        Positioned(
          top: -12,
          right: -12,
          child: Visibility(
            visible: canEdit,
            child: IconButton(
              key: AttachmentSectionWidget.redactBtnKey,
              onPressed: () => showRedactionWidget(
                context,
                eventId,
                roomId,
                sender,
              ),
              icon: const Icon(
                Atlas.minus_circle_thin,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> showRedactionWidget(
    BuildContext context,
    String eventId,
    String roomId,
    String senderId,
  ) async {
    final titleTextStyle = Theme.of(context).textTheme.titleMedium;
    final descriptionTextStyle = Theme.of(context).textTheme.bodyMedium;
    final TextEditingController reasonController = TextEditingController();
    await showAdaptiveDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(L10n.of(context).deleteAttachment, style: titleTextStyle),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    L10n.of(context).areYouSureYouWantToRemoveAttachmentFromPin,
                    style: descriptionTextStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InputTextField(
                    controller: reasonController,
                    hintText: L10n.of(context).reason,
                    textInputType: TextInputType.multiline,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(L10n.of(context).no),
                    ),
                    const SizedBox(width: 10),
                    ActerDangerActionButton(
                      key: AttachmentSectionWidget.confirmRedactKey,
                      onPressed: () {
                        Navigator.pop(context);
                        _handleRedactAttachment(
                          eventId,
                          reasonController.text.trim(),
                          context,
                        );
                      },
                      child: Text(L10n.of(context).yes),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRedactAttachment(
    String eventId,
    String reason,
    BuildContext context,
  ) async {
    EasyLoading.show(status: L10n.of(context).removingAttachment);
    try {
      await attachmentManager.redact(eventId, reason, null);
      _log.info('attachment redacted: $eventId');
      EasyLoading.dismiss();
    } catch (e) {
      _log.severe('attachment redaction failed', e, null);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToDeleteAttachment(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildAddAttachment(BuildContext context, WidgetRef ref) {
    final containerColor = Theme.of(context).colorScheme.surface;
    final iconColor = Theme.of(context).colorScheme.secondary;
    final iconTextStyle = Theme.of(context).textTheme.labelLarge;
    return InkWell(
      key: AttachmentSectionWidget.addAttachmentBtnKey,
      onTap: () => selectAttachment(
        context: context,
        onSelected: (files, selectedType) =>
            handleAttachmentSelected(context, ref, files, selectedType),
      ),
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add, color: iconColor),
            Text(
              L10n.of(context).add,
              style: iconTextStyle!.copyWith(color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  // if generic attachment, send via manager
  Future<void> handleAttachmentSelected(
    BuildContext context,
    WidgetRef ref,
    List<File> attachments,
    AttachmentType attachmentType,
  ) async {
    /// converts user selected media to attachment draft and sends state list.
    /// only supports image/video/audio/file.
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.sendingAttachment);
    final client = ref.read(alwaysClientProvider);
    final manager = attachmentManager;
    List<AttachmentDraft> drafts = [];
    try {
      for (var selected in attachments) {
        final file = selected;
        final mimeType = lookupMimeType(file.path);
        if (mimeType == null) throw lang.failedToDetectMimeType;
        if (attachmentType == AttachmentType.camera ||
            attachmentType == AttachmentType.image) {
          Uint8List bytes = await file.readAsBytes();
          final decodedImage = await decodeImageFromList(bytes);
          final imageDraft = client
              .imageDraft(file.path, mimeType)
              .size(bytes.length)
              .width(decodedImage.width)
              .height(decodedImage.height);
          final attachmentDraft = await manager.contentDraft(imageDraft);
          drafts.add(attachmentDraft);
        } else if (attachmentType == AttachmentType.audio) {
          Uint8List bytes = await file.readAsBytes();
          final audioDraft =
              client.audioDraft(file.path, mimeType).size(bytes.length);
          final attachmentDraft = await manager.contentDraft(audioDraft);
          drafts.add(attachmentDraft);
        } else if (attachmentType == AttachmentType.video) {
          Uint8List bytes = await file.readAsBytes();
          final videoDraft =
              client.videoDraft(file.path, mimeType).size(bytes.length);
          final attachmentDraft = await manager.contentDraft(videoDraft);
          drafts.add(attachmentDraft);
        } else {
          String fileName = file.path.split('/').last;
          final fileDraft = client
              .fileDraft(file.path, mimeType)
              .filename(fileName)
              .size(file.lengthSync());
          final attachmentDraft = await manager.contentDraft(fileDraft);
          drafts.add(attachmentDraft);
        }
      }
      for (var draft in drafts) {
        final res = await draft.send();
        _log.info('attachment sent: $res');
      }
      EasyLoading.dismiss();
    } catch (e) {
      _log.severe('Error sending attachments', e);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.errorSendingAttachment(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
