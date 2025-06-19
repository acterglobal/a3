import 'dart:io';
import 'dart:async';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // listen to the audio player state changes
      ref.listenManual(audioPlayerStateProvider, (previous, next) {
        if (next.messageId != widget.messageId &&
            next.state == PlayerState.playing) {
          _player.stop();
        }
      });

      // listen to the audio player state changes
      _player.onPlayerStateChanged.listen((state) {
        // if the messageId is not the same, return early
        // only update the state if this widget's messageId matches the current audio player
        final audioPlayerMessageId =
            ref.read(audioPlayerStateProvider).messageId;
        if (audioPlayerMessageId != widget.messageId) return;
        ref.read(audioPlayerStateProvider.notifier).state = (
          state: state,
          messageId: widget.messageId,
        );
      });
    });
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
    final mediaFile = mediaState.mediaFile;

    return audioUI(mediaFile, isDownloading: isDownloading);
  }

  Widget audioUI(File? mediaFile, {bool isDownloading = false}) {
    final audioPlayerInfo = ref.watch(audioPlayerStateProvider);
    final isPlaying =
        audioPlayerInfo.state == PlayerState.playing &&
        audioPlayerInfo.messageId == widget.messageId;
    final msgSize = widget.content.size();

    return Row(
      children: [
        if (isDownloading)
          CircularProgressIndicator()
        else if (mediaFile == null)
          IconButton.outlined(
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
          )
        else
          IconButton.outlined(
            onPressed: () => _handlePlayAudio(mediaFile),
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.content.body()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msgSize != null) Text(formatBytes(msgSize.truncate())),
                  if (widget.timestamp != null)
                    MessageTimestampWidget(
                      timestamp: widget.timestamp.expect('should not be null'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handlePlayAudio(File mediaFile) async {
    final mimetype = widget.content.mimetype();
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
            DeviceFileSource(mediaFile.path, mimeType: mimetype),
          );
          playerState = PlayerState.playing;
          break;
      }
      ref.read(audioPlayerStateProvider.notifier).state = (
        state: playerState,
        messageId: widget.messageId,
      );
    } catch (e, st) {
      debugPrint('Error playing audio: $e, \n $st');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
