import 'dart:io';

import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:video_player/video_player.dart';

class ActerVideoPlayer extends StatefulWidget {
  final File videoFile;
  final VoidCallback? onTapFullScreen;
  final bool? hasPlayerControls;

  const ActerVideoPlayer({
    super.key,
    required this.videoFile,
    this.onTapFullScreen,
    this.hasPlayerControls,
  });

  @override
  State<ActerVideoPlayer> createState() => _ActerVideoPlayerState();
}

class _ActerVideoPlayerState extends State<ActerVideoPlayer> {
  late VideoPlayerController _controller;
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  @override
  void initState() {
    super.initState();
    initVideoPlayer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> initVideoPlayer() async {
    _controller = VideoPlayerController.file(
      widget.videoFile,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [VideoPlayer(_controller), controlsOverlay()],
      ),
    );
  }

  Widget controlsOverlay() {
    final onTapFullScreen = widget.onTapFullScreen;
    return Stack(
      children: <Widget>[
        playButtonUI(),
        if (widget.hasPlayerControls != false) playPauseControls(),
        playbackSpeedMenu(),
        if (onTapFullScreen != null)
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              onPressed: () => onTapFullScreen(),
              icon: const Icon(Icons.square_outlined, size: 22.0),
            ),
          ),
      ],
    );
  }

  Widget playButtonUI() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 200),
      child:
          _controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                color: Colors.black26,
                child: Center(
                  child: Icon(
                    Icons.play_arrow,
                    size: 50.0,
                    semanticLabel: L10n.of(context).play,
                  ),
                ),
              ),
    );
  }

  Widget playPauseControls() {
    return GestureDetector(
      onTap: () {
        _controller.value.isPlaying ? _controller.pause() : _controller.play();
      },
    );
  }

  Widget playbackSpeedMenu() {
    return Align(
      alignment: Alignment.topLeft,
      child: PopupMenuButton<double>(
        initialValue: _controller.value.playbackSpeed,
        tooltip: L10n.of(context).playbackSpeed,
        onSelected: (double speed) {
          _controller.setPlaybackSpeed(speed);
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuItem<double>>[
            for (final double speed in _examplePlaybackRates)
              PopupMenuItem<double>(value: speed, child: Text('${speed}x')),
          ];
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            // Using less vertical padding as the text is also longer
            // horizontally, so it feels like it would need more spacing
            // horizontally (matching the aspect ratio of the video).
            vertical: 12,
            horizontal: 16,
          ),
          child: Text('${_controller.value.playbackSpeed}x'),
        ),
      ),
    );
  }
}
