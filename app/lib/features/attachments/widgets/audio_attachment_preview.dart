import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AudioAttachmentPreview extends StatefulWidget {
  final File file;

  const AudioAttachmentPreview({super.key, required this.file});

  @override
  State<AudioAttachmentPreview> createState() => _AudioAttachmentPreviewState();
}

class _AudioAttachmentPreviewState extends State<AudioAttachmentPreview> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_playerState == PlayerState.playing) await _audioPlayer.stop();
      _audioPlayer.onPlayerStateChanged.listen((state) {
        setState(() => _playerState = state);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(PhosphorIconsRegular.waveform, size: 200),
        IconButton.filled(
          onPressed: _playAudio,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.7),
          ),
          icon: Icon(
            _playerState == PlayerState.playing
                ? PhosphorIconsRegular.pause
                : PhosphorIconsRegular.play,
          ),
        ),
      ],
    );
  }

  Future<void> _playAudio() async {
    try {
      switch (_playerState) {
        case PlayerState.playing:
          await _audioPlayer.pause();
          break;
        case PlayerState.paused:
          await _audioPlayer.resume();
          break;
        case PlayerState.stopped:
        default:
          await _audioPlayer.play(DeviceFileSource(widget.file.path));
      }
    } catch (e, st) {
      debugPrint('Error playing audio: $e, \n $st');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
