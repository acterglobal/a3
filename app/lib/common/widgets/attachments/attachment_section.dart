import 'package:acter/common/dialogs/attachment_selection.dart';
import 'package:acter/common/providers/attachment_providers.dart';
import 'package:acter/common/widgets/attachments/attachment_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentsManager;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Attachment Section Widget
class AttachmentSectionWidget extends ConsumerWidget {
  final AttachmentsManager attachmentManager;
  final bool? canPostAttachment;
  const AttachmentSectionWidget({
    super.key,
    required this.attachmentManager,
    this.canPostAttachment = false,
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
                    for (var item in list) AttachmentItem(attachment: item),
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

  Widget _buildAddAttachment(BuildContext context, AttachmentsManager manager) {
    final containerColor = Theme.of(context).colorScheme.background;
    final iconColor = Theme.of(context).colorScheme.secondary;
    final iconTextStyle = Theme.of(context).textTheme.labelLarge;
    return InkWell(
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
