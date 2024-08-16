import 'package:acter/common/models/types.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/attachments/widgets/attachment_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Attachment, AttachmentsManager;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::attachments::section');

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
          error: (e, s) {
            _log.severe('Failed to load attachment manager', e, s);
            return onError(context, e);
          },
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
    final attachments = ref.watch(attachmentsProvider(attachmentManager));

    return attachments.when(
      data: (list) => attachmentData(list, context, ref),
      error: (e, s) {
        _log.severe('Failed to load attachments', e, s);
        return Text(L10n.of(context).errorLoadingAttachments(e));
      },
      loading: () => const Skeletonizer(
        child: Wrap(
          spacing: 5.0,
          runSpacing: 10.0,
          children: [],
        ),
      ),
    );
  }

  Widget attachmentData(
    List<Attachment> list,
    BuildContext context,
    WidgetRef ref,
  ) {
    bool canEdit = attachmentManager.canEditAttachments();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          attachmentHeader(context, ref),
          if (list.isEmpty) ...[
            const SizedBox(height: 10),
            Text(L10n.of(context).attachmentEmptyStateTitle),
          ],
          Wrap(
            spacing: 5.0,
            runSpacing: 10.0,
            children: <Widget>[
              for (var item in list)
                _buildAttachmentItem(context, item, canEdit),
            ],
          ),
        ],
      ),
    );
  }

  Widget attachmentHeader(BuildContext context, WidgetRef ref) {
    final attachmentTitleTextStyle = Theme.of(context).textTheme.labelLarge;
    return Row(
      children: [
        const Icon(Atlas.paperclip_attachment_thin, size: 14),
        const SizedBox(width: 5),
        Text(
          L10n.of(context).attachments,
          style: attachmentTitleTextStyle,
        ),
        const Spacer(),
        ActerInlineTextButton(
          onPressed: () => selectAttachment(
            context: context,
            onLinkSelected: (title, link) {
              Navigator.pop(context);
              return handleAttachmentSelected(
                context: context,
                ref: ref,
                manager: attachmentManager,
                title: title,
                link: link,
                attachmentType: AttachmentType.link,
                attachments: [],
              );
            },
            onSelected: (files, selectedType) {
              return handleAttachmentSelected(
                context: context,
                ref: ref,
                manager: attachmentManager,
                attachments: files,
                attachmentType: selectedType,
              );
            },
          ),
          child: Text(L10n.of(context).add),
        ),
      ],
    );
  }

  Widget _buildAttachmentItem(
    BuildContext context,
    Attachment item,
    bool canEdit,
  ) {
    final eventId = item.attachmentIdStr();
    return AttachmentItem(
      key: Key('$eventId-attachment'),
      attachment: item,
      canEdit: canEdit,
    );
  }
}
