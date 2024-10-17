import 'dart:math';

import 'package:flutter/material.dart';

import 'package:media_kit_video/media_kit_video.dart';

const _kVideoComponentMaxWidth = 1080.0;
const _kVideoComponentBaseWidth = 320.0;
const _kVideoComponentBaseHeight = 180.0;

class ResizableVidePlayer extends StatefulWidget {
  const ResizableVidePlayer({
    super.key,
    required this.src,
    required this.editable,
    required this.onResize,
    required this.width,
    required this.alignment,
    required this.controller,
    this.onLongPress,
    this.onDoubleTap,
  });

  final String src;
  final bool editable;
  final void Function(double width) onResize;
  final double width;
  final Alignment alignment;
  final VideoController controller;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  @override
  State<ResizableVidePlayer> createState() => _ResizableVidePlayerState();
}

class _ResizableVidePlayerState extends State<ResizableVidePlayer> {
  late double videoWidth = widget.width;

  double initialOffset = 0;
  double moveDistance = 0;

  bool onFocus = false;

  @override
  Widget build(BuildContext context) {
    final width = min(
      _kVideoComponentMaxWidth,
      max(_kVideoComponentBaseWidth, videoWidth - moveDistance),
    );

    // Calculate the height based on the width using the base aspect ratio
    // Width: _kVideoComponentBaseWidth
    // Height: _kVideoComponentBaseHeight
    final height =
        (width * _kVideoComponentBaseHeight) / _kVideoComponentBaseWidth;

    return Align(
      alignment: widget.alignment,
      child: SizedBox(
        width: width,
        height: height,
        child: MouseRegion(
          onEnter: (_) => setState(() => onFocus = true),
          onExit: (_) => setState(() => onFocus = false),
          child: Stack(
            children: [
              GestureDetector(
                onLongPress: widget.onLongPress,
                onDoubleTap: widget.onDoubleTap,
                child: Video(
                  controls: (state) => AdaptiveVideoControls(state),
                  controller: widget.controller,
                  width: 1080,
                  height: 720,
                  wakelock: false,
                ),
              ),
              _buildEdgeGesture(
                context,
                top: 0,
                left: 5,
                bottom: 0,
                width: 5,
                onUpdate: (distance) => setState(() => moveDistance = distance),
              ),
              _buildEdgeGesture(
                context,
                top: 0,
                right: 5,
                bottom: 0,
                width: 5,
                onUpdate: (distance) =>
                    setState(() => moveDistance = -distance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeGesture(
    BuildContext context, {
    double? top,
    double? left,
    double? right,
    double? bottom,
    double? width,
    void Function(double distance)? onUpdate,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      width: width,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          initialOffset = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          if (onUpdate != null) {
            final offset = details.globalPosition.dx - initialOffset;
            // if (widget.alignment == Alignment.center) {
            //   offset *= 2.0;
            // }
            onUpdate(offset);
          }
        },
        onHorizontalDragEnd: (details) {
          videoWidth = max(
            _kVideoComponentBaseWidth,
            videoWidth - moveDistance,
          );
          initialOffset = 0;
          moveDistance = 0;

          widget.onResize(videoWidth);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: onFocus
              ? Center(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5.0),
                      ),
                      border: Border.all(color: Colors.white),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
