import 'dart:io';
import 'dart:async';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::audio_message_event');

class AudioMessageEvent extends ConsumerStatefulWidget {
  final String roomId;
  final String messageId;
  final MsgContent content;
  final int? timestamp;

  const AudioMessageEvent({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.content,
    this.timestamp,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AudioMessageEventState();
}

class _AudioMessageEventState extends ConsumerState<AudioMessageEvent> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to global audio player state changes to stop this player when another starts
    ref.listenManual(audioPlayerStateProvider, (previous, next) {
      if (mounted &&
          next.messageId != widget.messageId &&
          next.state == PlayerState.playing) {
        _player.stop();
      }
    });

    // Listen to this player's state changes and update the global state accordingly
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      final currentAudioPlayerMessageId =
          ref.read(audioPlayerStateProvider).messageId;

      // Only update global state if this widget's messageId matches the current audio player
      if (currentAudioPlayerMessageId == widget.messageId) {
        ref.read(audioPlayerStateProvider.notifier).state = (
          state: state,
          messageId: widget.messageId,
        );
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChatMessageInfo messageInfo = (
      messageId: widget.messageId,
      roomId: widget.roomId,
    );
    final mediaState = ref.watch(mediaChatStateProvider(messageInfo));
    final isDownloading =
        mediaState.mediaChatLoadingState.isLoading || mediaState.isDownloading;

    return _buildAudioEventUI(mediaState.mediaFile, isDownloading);
  }

  Widget _buildAudioEventUI(File? mediaFile, bool isDownloading) {
    final msgSize = widget.content.size();
    final defaultWidth = defaultMessageMaxWidth(context);

    return Container(
      constraints: BoxConstraints(maxWidth: defaultWidth),
      child: Row(
        children: [
          _buildAudioControls(mediaFile, isDownloading),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content.body(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (msgSize != null) Text(formatBytes(msgSize.truncate())),
                    Spacer(),
                    if (widget.timestamp != null)
                      MessageTimestampWidget(
                        timestamp: widget.timestamp.expect(
                          'should not be null',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls(File? mediaFile, bool isDownloading) {
    final audioPlayerInfo = ref.watch(audioPlayerStateProvider);
    final isPlaying =
        audioPlayerInfo.state == PlayerState.playing &&
        audioPlayerInfo.messageId == widget.messageId;

    // if the media is still downloading, show a loading indicator
    if (isDownloading) return const CircularProgressIndicator();

    // if the media is not downloaded, show a download button
    if (mediaFile == null) {
      return IconButton.outlined(
        onPressed: () async {
          final notifier = ref.read(
            mediaChatStateProvider((
              messageId: widget.messageId,
              roomId: widget.roomId,
            )).notifier,
          );
          await notifier.downloadMedia();
        },
        icon: Icon(Icons.download),
      );
    } else {
      // if the media is downloaded, show a play/pause button
      return IconButton.outlined(
        onPressed: () => _handlePlayAudio(mediaFile),
        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      );
    }
  }

  Future<void> _handlePlayAudio(File mediaFile) async {
    try {
      PlayerState playerState;
      switch (_player.state) {
        case PlayerState.playing:
          await _player.pause();
          playerState = PlayerState.paused;
          break;
        case PlayerState.paused:
          await _player.resume();
          playerState = PlayerState.playing;
          break;
        case PlayerState.stopped:
        default:
          await _player.play(
            DeviceFileSource(
              mediaFile.path,
              mimeType: widget.content.mimetype(),
            ),
          );
          playerState = PlayerState.playing;
          break;
      }
      ref.read(audioPlayerStateProvider.notifier).state = (
        state: playerState,
        messageId: widget.messageId,
      );
    } catch (e, st) {
      _log.severe('Error playing audio: $e, \n $st');
    }
  }
}
