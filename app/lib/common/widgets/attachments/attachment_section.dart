import 'package:acter/common/dialogs/attachment_selection.dart';
import 'package:acter/common/providers/attachment_providers.dart';

import 'package:acter/common/widgets/attachments/attachment_item.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Attachment, AttachmentsManager;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::attachments');

/// Attachment Section Widget
class AttachmentSectionWidget extends ConsumerWidget {
  static const redactBtnKey = Key('attachments-redact-btn');
  static const addAttachmentBtnKey = Key('attachments-add-btn');
  static const confirmRedactKey = Key('attachments-confirm-redact');

  final AttachmentsManager attachmentManager;
  final bool? canPostAttachment;
  final bool? canRedact;
  const AttachmentSectionWidget({
    super.key,
    required this.attachmentManager,
    this.canPostAttachment = false,
    this.canRedact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentTitleTextStyle = Theme.of(context).textTheme.labelLarge;
    final attachments = ref.watch(attachmentsProvider(attachmentManager));
    return attachments.when(
      data: (list) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Text('Attachments', style: attachmentTitleTextStyle),
                  const SizedBox(width: 5),
                  const Icon(Atlas.paperclip_attachment_thin, size: 14),
                  const SizedBox(width: 5),
                  Text('${list.length}'),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 5.0,
                runSpacing: 10.0,
                children: <Widget>[
                  if (list.isNotEmpty)
                    for (var item in list) _buildAttachmentItem(context, item),
                  if (canPostAttachment!)
                    _buildAddAttachment(context, attachmentManager),
                ],
              ),
            ],
          ),
        );
      },
      error: (err, st) => Text('Error loading attachments $err'),
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
  ) {
    final eventId = item.attachmentIdStr();
    final roomId = item.roomIdStr();
    final sender = item.sender();
    return Stack(
      children: [
        AttachmentItem(
          key: Key(eventId),
          attachment: item,
        ),
        Positioned(
          top: -12,
          right: -12,
          child: Visibility(
            visible: canRedact!,
            child: IconButton(
              key: redactBtnKey,
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
    final confirmBtnColor = Theme.of(context).colorScheme.errorContainer;
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
                Text('Delete attachment', style: titleTextStyle),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Are you sure you want to remove this attachment from pin?',
                    style: descriptionTextStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InputTextField(
                    controller: reasonController,
                    hintText: 'Reason',
                    textInputType: TextInputType.multiline,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('No'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      key: confirmRedactKey,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleRedactAttachment(
                          eventId,
                          reasonController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmBtnColor,
                      ),
                      child: const Text('Yes'),
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

  Future<void> _handleRedactAttachment(String eventId, String reason) async {
    EasyLoading.show(status: 'Removing attachment', dismissOnTap: false);
    try {
      await attachmentManager.redact(eventId, reason, null);
      _log.info('attachment redacted: $eventId');
      EasyLoading.dismiss();
    } catch (e) {
      _log.severe('attachment redaction failed', e, null);
      EasyLoading.showError('Failed to delete attachment due to $e');
    }
  }

  Widget _buildAddAttachment(BuildContext context, AttachmentsManager manager) {
    final containerColor = Theme.of(context).colorScheme.background;
    final iconColor = Theme.of(context).colorScheme.secondary;
    final iconTextStyle = Theme.of(context).textTheme.labelLarge;
    return InkWell(
      key: AttachmentSectionWidget.addAttachmentBtnKey,
      onTap: () => showAttachmentSelection(context, manager),
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
            Text('Add', style: iconTextStyle!.copyWith(color: iconColor)),
          ],
        ),
      ),
    );
  }
}
