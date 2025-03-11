import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/features/attachments/providers/notifiers/attachments_notifiers.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

/// Provider the profile data of a the given space, keeps up to date with underlying client
final attachmentsManagerProvider = AsyncNotifierProvider.autoDispose.family<
  AttachmentsManagerNotifier,
  AttachmentsManager,
  AttachmentsManagerProvider
>(() => AttachmentsManagerNotifier());

/// provider for getting attachments, keeps up-to-date with live manager object
final attachmentsProvider = FutureProvider.family
    .autoDispose<List<Attachment>, AttachmentsManager>((ref, manager) async {
      return (await manager.attachments()).toList();
    });

/// Provider for getting reference attachments
final referenceAttachmentsProvider = FutureProvider.family
    .autoDispose<List<Attachment>, AttachmentsManager>((ref, manager) async {
      final attachmentList = await ref.watch(
        attachmentsProvider(manager).future,
      );
      final refAttachmentList =
          attachmentList.where((item) => item.refDetails() != null).toList();
      return refAttachmentList;
    });

/// Provider for getting msgContent attachments
final msgContentAttachmentsProvider = FutureProvider.family
    .autoDispose<List<Attachment>, AttachmentsManager>((ref, manager) async {
      final attachmentList = await ref.watch(
        attachmentsProvider(manager).future,
      );
      final msgContentAttachmentList =
          attachmentList.where((item) => item.msgContent() != null).toList();
      return msgContentAttachmentList;
    });

final attachmentMediaStateProvider = StateNotifierProvider.family
    .autoDispose<AttachmentMediaNotifier, AttachmentMediaState, Attachment>(
      (ref, attachment) =>
          AttachmentMediaNotifier(attachment: attachment, ref: ref),
    );
