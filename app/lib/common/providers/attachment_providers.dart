import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/providers/notifiers/attachments_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

/// Provider the profile data of a the given space, keeps up to date with underlying client
final attachmentsManagerProvider = NotifierProvider.family<
    AttachmentsManagerNotifier, AttachmentsManager, AttachmentsManager>(
  () => AttachmentsManagerNotifier(),
);

/// provider for getting attachments, keeps up-to-date with live manager object
final attachmentsProvider = FutureProvider.family
    .autoDispose<List<Attachment>, AttachmentsManager>((ref, manager) async {
  final liveManager = ref.watch(attachmentsManagerProvider(manager));
  return (await liveManager.attachments()).toList();
});

final attachmentMediaStateProvider = StateNotifierProvider.family
    .autoDispose<AttachmentMediaNotifier, AttachmentMediaState, Attachment>(
  (ref, attachment) =>
      AttachmentMediaNotifier(attachment: attachment, ref: ref),
);
