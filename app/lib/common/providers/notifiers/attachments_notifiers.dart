import 'dart:async';
import 'dart:io';

import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::attachments');

// ignore_for_file: unused_field

class AttachmentsManagerNotifier
    extends FamilyNotifier<AttachmentsManager, AttachmentsManager> {
  late Stream<void> _listener;
  late StreamSubscription<void> _poller;

  @override
  AttachmentsManager build(AttachmentsManager arg) {
    _listener = arg.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        _log.info('attempting to reload');
        final newManager = await arg.reload();
        _log.info(
          'manager updated. attachments: ${newManager.attachmentsCount()}',
        );
        state = newManager;
      },
      onError: (e, stack) {
        _log.severe('stream errored.', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    return arg;
  }
}

class AttachmentMediaNotifier extends StateNotifier<AttachmentMediaState> {
  final Ref ref;
  final AttachmentMediaInfo mediaInfo;
  AttachmentMediaNotifier({
    required this.mediaInfo,
    required this.ref,
  }) : super(const AttachmentMediaState()) {
    _init();
  }

  void _init() async {
    final spaceId = mediaInfo.spaceId;
    final attachmentId = mediaInfo.attachmentId;
    final space = await ref.read(spaceProvider(spaceId).future);
    state = state.copyWith(
      mediaLoadingState: const AttachmentMediaLoadingState.loading(),
    );

    try {
      //Get media path if already downloaded
      final mediaPath = await space.mediaPath(attachmentId, false);
      if (mediaPath.text() != null) {
        state = state.copyWith(
          mediaFile: File(mediaPath.text()!),
          mediaLoadingState: const AttachmentMediaLoadingState.loaded(),
        );
      } else {
        state = state.copyWith(
          mediaLoadingState: const AttachmentMediaLoadingState.error(
            'Media not found',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        mediaLoadingState: AttachmentMediaLoadingState.error(
          'Some error occurred ${e.toString()}',
        ),
      );
    }
  }

  Future<void> downloadMedia() async {
    final spaceId = mediaInfo.spaceId;
    final attachmentId = mediaInfo.attachmentId;

    state = state.copyWith(isDownloading: true);
    final space = await ref.read(spaceProvider(spaceId).future);
    //Download media if media path is not available
    final tempDir = await getTemporaryDirectory();
    final result = await space.downloadMedia(
      attachmentId,
      null,
      tempDir.path,
    );
    String? mediaPath = result.text();
    if (mediaPath != null) {
      state = state.copyWith(
        mediaFile: File(mediaPath),
        isDownloading: false,
      );
    }
  }
}
