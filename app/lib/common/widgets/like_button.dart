import 'package:effektio/common/animations/like_animation.dart';
import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LikeButton extends StatefulWidget {
  final String likeCount;
  final TextStyle style;
  final Color color;
  final int index;

  const LikeButton({
    Key? key,
    required this.likeCount,
    required this.style,
    required this.color,
    required this.index,
  }) : super(key: key);

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

    heartSize = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.0, end: 1.08).chain(
            CurveTween(curve: Curves.easeOut),
          ),
          weight: 30.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.08, end: 1.0).chain(
            CurveTween(curve: const Cubic(0.71, -0.01, 1.0, 1.0)),
          ),
          weight: 30.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.0, end: 0.8).chain(
            CurveTween(curve: Curves.linear),
          ),
          weight: 20.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.8, end: 1.0).chain(
            CurveTween(curve: Curves.elasticIn),
          ),
          weight: 20.0,
        ),
      ],
    ).animate(CurvedAnimation(parent: controller, curve: const Interval(0, 1)));

    smallHeartOpacity = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: Curves.fastOutSlowIn),
          ),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.0, end: 0.0).chain(
            CurveTween(curve: Curves.fastOutSlowIn),
          ),
          weight: 50.0,
        ),
      ],
    ).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 0.7)),
    );

    sizedBoxsize = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.0, end: 0.7).chain(
            CurveTween(curve: Curves.fastOutSlowIn),
          ),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.7, end: 1.0).chain(
            CurveTween(curve: Curves.fastOutSlowIn),
          ),
          weight: 50.0,
        ),
      ],
    ).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 0.7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Text(widget.likeCount, style: widget.style),
        AnimatedBuilder(
          animation: controller,
          builder: (context, w) {
            return SizedBox(
              height: 65 * sizedBoxsize.value,
              width: 65 * sizedBoxsize.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      bool liked =
                          LikeAnimation.likedIndex.contains(widget.index);
                      if (!liked) {
                        LikeAnimation.likedIndex.add(widget.index);
                        controller.reset();
                        controller.forward();
                      } else {
                        LikeAnimation.likedIndex.remove(widget.index);
                        setState(() {});
                      }
                    },
                    child: LikeAnimation.likedIndex.contains(widget.index)
                        ? _LikeWidget(
                            size: Size(
                              heartSize.value * 30,
                              heartSize.value * 30,
                            ),
                            iconName: 'like_filled',
                            color: AppCommonTheme.primaryColor,
                            isSmall: false,
                          )
                        : _LikeWidget(
                            size: Size(
                              heartSize.value * 30,
                              heartSize.value * 30,
                            ),
                            iconName: 'heart',
                            color: widget.color,
                            isSmall: false,
                          ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child:
                        _SmallHeartWidget(smallHeartOpacity: smallHeartOpacity),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child:
                        _SmallHeartWidget(smallHeartOpacity: smallHeartOpacity),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child:
                        _SmallHeartWidget(smallHeartOpacity: smallHeartOpacity),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child:
                        _SmallHeartWidget(smallHeartOpacity: smallHeartOpacity),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LikeWidget extends StatelessWidget {
  const _LikeWidget({
    required this.size,
    required this.iconName,
    required this.color,
    required this.isSmall,
  });

  final Size size;
  final String iconName;
  final Color color;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/$iconName.svg',
      color: color,
      width: size.height,
      height: size.width,
    );
  }
}

class _SmallHeartWidget extends StatelessWidget {
  const _SmallHeartWidget({
    required this.smallHeartOpacity,
  });

  final Animation<double> smallHeartOpacity;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.favorite,
      color: AppCommonTheme.primaryColor
          .withOpacity(smallHeartOpacity.value * 0.8),
      size: 12,
    );
  }
}
