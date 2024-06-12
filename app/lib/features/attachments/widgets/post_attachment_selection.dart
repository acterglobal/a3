import 'dart:typed_data';

import 'package:acter/common/models/types.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/attachments/widgets/attachment_draft_item.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentDraft, AttachmentsManager;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';

final _log = Logger('a3::common::attachments');

class PostAttachmentSelection extends ConsumerStatefulWidget {
  final List<AttachmentInfo> attachments;
  final AttachmentsManager manager;

  const PostAttachmentSelection({
    super.key,
    required this.attachments,
    required this.manager,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PostAttachmentSelectionState();
}

class _PostAttachmentSelectionState
    extends ConsumerState<PostAttachmentSelection> {
  @override
  Widget build(BuildContext context) {
    final attachments = widget.attachments;
    final titleTextStyle = Theme.of(context).textTheme.titleSmall;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Attachments Selected (${attachments.length})',
            style: titleTextStyle,
          ),
        ),
        const SizedBox(height: 15),
        _buildSelectedDrafts(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildSelectedDrafts() => Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 5.0,
          runSpacing: 10.0,
          children: List.generate(
            widget.attachments.length,
            (idx) =>
                AttachmentDraftItem(attachmentDraft: widget.attachments[idx]),
          ),
        ),
      );

  // send/cancel buttons
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              Navigator.of(context).pop();
              handleAttachmentSend();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // if generic attachment, send via manager
  Future<void> handleAttachmentSend() async {
    /// converts user selected media to attachment draft and sends state list.
    /// only supports image/video/audio/file.
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.sendingAttachment);
    final client = ref.read(alwaysClientProvider);
    List<AttachmentDraft> drafts = [];
    try {
      for (var selected in widget.attachments) {
        final type = selected.type;
        final file = selected.file;
        final mimeType = lookupMimeType(file.path);
        if (mimeType == null) throw lang.failedToDetectMimeType;
        final manager = widget.manager;
        if (type == AttachmentType.camera || type == AttachmentType.image) {
          Uint8List bytes = await file.readAsBytes();
          final decodedImage = await decodeImageFromList(bytes);
          final imageDraft = client
              .imageDraft(file.path, mimeType)
              .size(bytes.length)
              .width(decodedImage.width)
              .height(decodedImage.height);
          final attachmentDraft = await manager.contentDraft(imageDraft);
          drafts.add(attachmentDraft);
        } else if (type == AttachmentType.audio) {
          Uint8List bytes = await file.readAsBytes();
          final audioDraft =
              client.audioDraft(file.path, mimeType).size(bytes.length);
          final attachmentDraft = await manager.contentDraft(audioDraft);
          drafts.add(attachmentDraft);
        } else if (type == AttachmentType.video) {
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
