import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/common/widgets/visibility/shadow_effect_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::like_button');

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final TextStyle? style;
  final Color color;
  final Future<void> Function() onTap;

  const LikeButton({
    super.key,
    required this.likeCount,
    this.style,
    required this.color,
    this.isLiked = false,
    required this.onTap,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> heartSize;
  late Animation<double> smallHeartOpacity;
  late Animation<double> sizedBoxsize;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    LikeAnimation.controller = controller;

    heartSize = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: const Cubic(0.71, -0.01, 1.0, 1.0))),
        weight: 30.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 1.0,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 20.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 0.8,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticIn)),
        weight: 20.0,
      ),
    ]).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 1)),
    );

    smallHeartOpacity = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 50.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 50.0,
      ),
    ]).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 0.7)),
    );

    sizedBoxsize = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 1.0,
          end: 0.7,
        ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 50.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween(
          begin: 0.7,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 50.0,
      ),
    ]).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 0.7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AnimatedBuilder(
          animation: controller,
          builder: (context, w) {
            return SizedBox(
              height: 55 * sizedBoxsize.value,
              width: 55 * sizedBoxsize.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InkWell(
                    onTap: () async {
                      _log.info('like click --------------------------------');
                      await widget.onTap();
                      if (!widget.isLiked) {
                        controller.reset();
                        controller.forward();
                      } else {
                        if (mounted) {
                          setState(() {});
                        }
                      }
                    },
                    child: ShadowEffectWidget(
                      child: _LikeWidget(
                        size: Size(heartSize.value * 30, heartSize.value * 30),
                        icon:
                            widget.isLiked
                                ? Icon(
                                  Atlas.heart,
                                  fill: 1.0,
                                  color: Theme.of(context).colorScheme.error,
                                )
                                : const Icon(Atlas.heart),
                        color:
                            widget.isLiked
                                ? Theme.of(context).colorScheme.tertiary
                                : widget.color,
                        isSmall: false,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: _SmallHeartWidget(
                      smallHeartOpacity: smallHeartOpacity,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: _SmallHeartWidget(
                      smallHeartOpacity: smallHeartOpacity,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: _SmallHeartWidget(
                      smallHeartOpacity: smallHeartOpacity,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _SmallHeartWidget(
                      smallHeartOpacity: smallHeartOpacity,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        ShadowEffectWidget(
          child: Text(widget.likeCount.toString(), style: widget.style),
        ),
      ],
    );
  }
}

class _LikeWidget extends StatelessWidget {
  const _LikeWidget({
    required this.size,
    required this.icon,
    required this.color,
    required this.isSmall,
  });

  final Size size;
  final Widget icon;
  final Color color;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return icon;
  }
}

class _SmallHeartWidget extends StatelessWidget {
  const _SmallHeartWidget({required this.smallHeartOpacity});

  final Animation<double> smallHeartOpacity;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.favorite,
      color: Theme.of(
        context,
      ).colorScheme.tertiary.withValues(alpha: smallHeartOpacity.value * 0.8),
      size: 12,
    );
  }
}
