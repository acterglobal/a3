import 'package:acter/common/providers/notifiers/attachments_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider the profile data of a the given space, keeps up to date with underlying client
final attachmentsManagerProvider = NotifierProvider.family<
    AttachmentsManagerNotifier, AttachmentsManager, AttachmentsManager>(
  () => AttachmentsManagerNotifier(),
);

/// provider for handling attachment drafts that user selected.
final attachmentDraftsProvider = StateNotifierProvider.family<
    AttachmentDraftsNotifier, List<AttachmentDraft>, AttachmentsManager>(
  (ref, manager) => AttachmentDraftsNotifier(manager: manager, ref: ref),
);
