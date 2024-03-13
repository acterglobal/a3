import 'dart:io';
import 'package:acter/common/providers/attachment_providers.dart';
import 'package:acter/common/widgets/attachments/attachment_draft_item.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentsManager, Convo;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';

final _log = Logger('a3::common::attachments');

class PostAttachmentSelection extends ConsumerStatefulWidget {
  final List<File> files;
  final AttachmentsManager? manager;
  final Convo? convo;

  const PostAttachmentSelection({
    super.key,
    required this.files,
    required this.manager,
    this.convo,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PostAttachmentSelectionState();
}

class _PostAttachmentSelectionState
    extends ConsumerState<PostAttachmentSelection> {
  @override
  Widget build(BuildContext context) {
    final files = widget.files;
    final titleTextStyle = Theme.of(context).textTheme.titleSmall;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Attachments Selected (${files.length})',
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
            widget.files.length,
            (idx) => AttachmentDraftItem(file: widget.files[idx]),
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
          ElevatedButton(
            onPressed: () async {
              // we are popping out twice to clear selection sheet too!
              Navigator.of(context).pop();
              if (widget.convo != null) {
                handleChatAttachmentSend(widget.files);
              } else if (widget.manager != null) {
                handleAttachmentSend();
              }
              // manager not present, this shouldn't lead up here
              return;
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // if generic attachment, send via manager
  void handleAttachmentSend() async {
    final attachmentDraftsNotifier =
        ref.read(attachmentDraftsProvider(widget.manager!).notifier);
    for (var file in widget.files) {
      await attachmentDraftsNotifier.sendDrafts(file);
    }
  }

  // if room attachment, send via timeline stream message
  void handleChatAttachmentSend(
    List<File> selectedAttachments,
  ) async {
    final roomId = widget.convo!.getRoomIdStr();
    final client = ref.read(alwaysClientProvider);
    final inputState = ref.read(chatInputProvider(roomId));
    final stream = widget.convo!.timelineStream();

    try {
      for (var file in selectedAttachments) {
        final mimeType = lookupMimeType(file.path)!;
        if (mimeType.startsWith('image/')) {
          final bytes = file.readAsBytesSync();
          final image = await decodeImageFromList(bytes);
          final imageDraft = client
              .imageDraft(file.path, mimeType)
              .size(file.lengthSync())
              .width(image.width)
              .height(image.height);
          if (inputState.repliedToMessage != null) {
            await stream.replyMessage(
              inputState.repliedToMessage!.id,
              imageDraft,
            );
          } else {
            await stream.sendMessage(imageDraft);
          }
        } else if (mimeType.startsWith('audio/')) {
          final audioDraft =
              client.audioDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.repliedToMessage != null) {
            await stream.replyMessage(
              inputState.repliedToMessage!.id,
              audioDraft,
            );
          } else {
            await stream.sendMessage(audioDraft);
          }
        } else if (mimeType.startsWith('video/')) {
          final videoDraft =
              client.videoDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.repliedToMessage != null) {
            await stream.replyMessage(
              inputState.repliedToMessage!.id,
              videoDraft,
            );
          } else {
            await stream.sendMessage(videoDraft);
          }
        } else {
          final draft =
              client.fileDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.repliedToMessage != null) {
            await stream.replyMessage(inputState.repliedToMessage!.id, draft);
          } else {
            await stream.sendMessage(draft);
          }
        }
      }
    } catch (e, s) {
      _log.severe('error occurred sending attachments', e, s);
    }

    if (inputState.repliedToMessage != null) {
      final notifier = ref.read(chatInputProvider(roomId).notifier);
      notifier.setRepliedToMessage(null);
      notifier.setEditMessage(null);
      notifier.showReplyView(false);
      notifier.showEditView(false);
      notifier.setReplyWidget(null);
      notifier.setEditWidget(null);
    }
  }
}
