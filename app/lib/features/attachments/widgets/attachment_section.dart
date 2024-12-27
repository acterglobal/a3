import 'package:acter/common/actions/add_space_object_ref.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/msg_content_attachment_item.dart';
import 'package:acter/features/attachments/widgets/reference_attachment_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentsManager;
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          referenceAttachmentsUI(context, ref),
          msgContentAttachmentsUI(context, ref),
        ],
      ),
    );
  }

  Widget referenceAttachmentsUI(
    BuildContext context,
    WidgetRef ref,
  ) {
    final lang = L10n.of(context);
    final referenceAttachmentsLoader =
        ref.watch(referenceAttachmentsProvider(attachmentManager));
    bool canEdit = attachmentManager.canEditAttachments();

    return referenceAttachmentsLoader.when(
      data: (refAttachmentList) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            attachmentHeader(
              context: context,
              title: lang.references,
              onTapAdd: () => addSpaceObjectRefDialog(
                context: context,
                attachmentManager: attachmentManager,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: refAttachmentList.length,
              padding: EdgeInsets.zero,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return ReferenceAttachmentItem(
                  attachment: refAttachmentList[index],
                  canEdit: canEdit,
                );
              },
            ),
            if (refAttachmentList.isEmpty)
              Text(L10n.of(context).referencesEmptyStateTitle),
            const SizedBox(height: 20),
          ],
        );
      },
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

  Widget msgContentAttachmentsUI(
    BuildContext context,
    WidgetRef ref,
  ) {
    final lang = L10n.of(context);
    final msgContentAttachmentsLoader =
        ref.watch(msgContentAttachmentsProvider(attachmentManager));
    bool canEdit = attachmentManager.canEditAttachments();

    return msgContentAttachmentsLoader.when(
      data: (msgContentAttachmentList) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            attachmentHeader(
              context: context,
              title: lang.attachments,
              onTapAdd: () => selectAttachment(
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
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: msgContentAttachmentList.length,
              padding: EdgeInsets.zero,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return MsgContentAttachmentItem(
                  attachment: msgContentAttachmentList[index],
                  canEdit: canEdit,
                );
              },
            ),
            if (msgContentAttachmentList.isEmpty)
              Text(L10n.of(context).attachmentEmptyStateTitle),
          ],
        );
      },
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

  Widget attachmentHeader({
    required BuildContext context,
    required String title,
    required VoidCallback? onTapAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(onPressed: onTapAdd, icon: Icon(Icons.add)),
      ],
    );
  }
}
