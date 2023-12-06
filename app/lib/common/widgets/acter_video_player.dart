import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ActerVideoPlayer extends StatefulWidget {
  final File videoFile;
  final VoidCallback? onTapFullScreen;

  const ActerVideoPlayer({
    super.key,
    required this.videoFile,
    this.onTapFullScreen,
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
    super.dispose();
    _controller.dispose();
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
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          controlsOverlay(),
        ],
      ),
    );
  }

  Widget controlsOverlay() {
    return Stack(
      children: <Widget>[
        playButtonUI(),
        playPauseControls(),
        playbackSpeedMenu(),
        if (widget.onTapFullScreen != null) fullScreenActionButton(),
      ],
    );
  }

  Widget playButtonUI() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 200),
      child: _controller.value.isPlaying
          ? const SizedBox.shrink()
          : Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(
                  Icons.play_arrow,
                  size: 50.0,
                  semanticLabel: 'Play',
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
      alignment: Alignment.topRight,
      child: PopupMenuButton<double>(
        initialValue: _controller.value.playbackSpeed,
        tooltip: 'Playback speed',
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

  Widget fullScreenActionButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: IconButton(
        onPressed: () => widget.onTapFullScreen!(),
        icon: const Icon(
          Icons.square_outlined,
          size: 22.0,
        ),
      ),
    );
  }
}
