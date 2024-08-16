import 'package:acter/common/models/types.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/pins/Utils/pins_utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void manageBackwardPinLinkSupport(BuildContext context, WidgetRef ref, ActerPin pin) async {
  if (pin.isLink() && pin.url().toString().isNotEmpty) {
    String link = pin.url().toString();
    var manager =
        await ref.watch(attachmentsManagerProvider(pin.attachments()).future);
    if (!context.mounted) return;
    //Test Pin Link Empty
    await savePinLink(context, pin, '');
    if (!context.mounted) return;
    //Add pin link to attachment
    await handleAttachmentSelected(
      context: context,
      ref: ref,
      manager: manager,
      title: '',
      link: link,
      attachmentType: AttachmentType.link,
      attachments: [],
    );
  }
}
