import 'package:acter/features/attachments/widgets/msg_content_attachment_item.dart';
import 'package:acter/features/attachments/widgets/reference_attachment_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::attachments::widget::attachment_item');

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
    // FIXME: maybe we want to exclude the link here already as well?
    final msgContent = attachment.msgContent();
    if (msgContent != null) {
      // we have a msgContent based Item
      return MsgContentAttachmentItem(
        attachment: attachment,
        canEdit: canEdit,
        openView: openView,
        msgContent: msgContent,
      );
    }
    // we have a reference type instead
    final refDetails = attachment.refDetails();
    if (refDetails != null) {
      // here goes the new ref-details code
      return ReferenceAttachmentItem(
        attachment: attachment,
        canEdit: canEdit,
        openView: openView,
        refDetails: refDetails,
      );
    }

    // in practice it must be either of them!
    _log.severe('Neither RefDetails nor Content found on attachment item');
    return ListTile(
      leading: PhosphorIcon(PhosphorIconsThin.warningCircle),
      title: Text(L10n.of(context).loadingFailed(attachment.typeStr())),
    );
  }
}
