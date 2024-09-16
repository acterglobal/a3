import 'dart:async';
import 'dart:io';

import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::attachments::notifiers');

class AttachmentsManagerNotifier extends AutoDisposeFamilyAsyncNotifier<
    AttachmentsManager, Future<AttachmentsManager>> {
  late Stream<void> _listener;
  late StreamSubscription<void> _poller;

  @override
  FutureOr<AttachmentsManager> build(Future<AttachmentsManager> arg) async {
    final manager = await arg;
    _listener = manager.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        _log.info('attempting to reload');
        final newManager = await manager.reload();
        final count = newManager.attachmentsCount();
        _log.info('manager updated. attachments: $count');
        state = AsyncValue.data(newManager);
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return manager;
  }
}

class AttachmentMediaNotifier extends StateNotifier<AttachmentMediaState> {
  final Ref ref;
  final Attachment attachment;
  AttachmentMediaNotifier({
    required this.attachment,
    required this.ref,
  }) : super(const AttachmentMediaState()) {
    _init();
  }

  void _init() async {
    state = state.copyWith(
      mediaLoadingState: const AttachmentMediaLoadingState.loading(),
    );

    try {
      //Get media path if already downloaded
      final mediaPath = await attachment.mediaPath(false);
      state = mediaPath.text().let(
                (p0) => state.copyWith(
                  mediaFile: File(p0),
                  mediaLoadingState: const AttachmentMediaLoadingState.loaded(),
                ),
              ) ??
          state.copyWith(
            mediaLoadingState:
                const AttachmentMediaLoadingState.error('Media not found'),
          );
    } catch (e) {
      state = state.copyWith(
        mediaLoadingState: AttachmentMediaLoadingState.error(
          'Some error occurred ${e.toString()}',
        ),
      );
    }
  }

  Future<void> downloadMedia() async {
    state = state.copyWith(isDownloading: true);
    //Download media if media path is not available
    final tempDir = await getTemporaryDirectory();
    final result = await attachment.downloadMedia(null, tempDir.path);
    result.text().let((p0) {
      state = state.copyWith(
        mediaFile: File(p0),
        isDownloading: false,
      );
    });
  }
}
