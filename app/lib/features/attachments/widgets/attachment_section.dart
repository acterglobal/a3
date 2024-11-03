import 'package:acter/common/models/types.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Attachment, AttachmentsManager;
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
  final AttachmentsManagerProvider? manager;

  const AttachmentSectionWidget({
    super.key,
    this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerProvider = manager;
    if (managerProvider == null) {
      return loading();
    }
    final managerLoader =
        ref.watch(attachmentsManagerProvider(managerProvider));
    return managerLoader.when(
      data: (manager) => FoundAttachmentSectionWidget(
        attachmentManager: manager,
        key: attachmentsKey,
      ),
      error: (e, s) {
        _log.severe('Failed to load attachment manager', e, s);
        return onError(context, e);
      },
      loading: loading,
    );
  }

  Widget onError(BuildContext context, Object error) {
    final lang = L10n.of(context);
    return Column(
      children: [
        Text(lang.attachments),
        Text(lang.loadingFailed(error)),
      ],
    );
  }

  static Widget loading() {
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
    super.key,
    required this.attachmentManager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsLoader = ref.watch(attachmentsProvider(attachmentManager));
    return attachmentsLoader.when(
      data: (attachments) => attachmentData(attachments, context, ref),
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
              for (final item in list)
                _buildAttachmentItem(context, item, canEdit),
            ],
          ),
        ],
      ),
    );
  }

  Widget attachmentHeader(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final attachmentTitleTextStyle = Theme.of(context).textTheme.titleSmall;
    return Row(
      children: [
        Text(lang.attachments, style: attachmentTitleTextStyle),
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
          child: Text(lang.add),
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
