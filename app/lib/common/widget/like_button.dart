import 'package:effektio/blocs/like_animation.dart';
import 'package:effektio/common/store/separatedThemes.dart';
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
  late Animation<double> _heartSize;
  late Animation<double> _smallHeartOpacity;
  late Animation<double> _sizedBoxsize;

  @override
  void initState() {
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    LikeAnimation.controller = controller;

    _heartSize = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.0, end: 1.08)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.08, end: 1.0)
              .chain(CurveTween(curve: const Cubic(0.71, -0.01, 1.0, 1.0))),
          weight: 30.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.0, end: 0.8)
              .chain(CurveTween(curve: Curves.linear)),
          weight: 20.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.8, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticIn)),
          weight: 20.0,
        ),
      ],
    ).animate(CurvedAnimation(parent: controller, curve: const Interval(0, 1)));

    _smallHeartOpacity = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.fastOutSlowIn)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.fastOutSlowIn)),
          weight: 50.0,
        ),
      ],
    ).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 0.7)),
    );

    _sizedBoxsize = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(begin: 1.0, end: 0.7)
              .chain(CurveTween(curve: Curves.fastOutSlowIn)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.7, end: 1.0)
              .chain(CurveTween(curve: Curves.fastOutSlowIn)),
          weight: 50.0,
        ),
      ],
    ).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 0.7)),
    );
    super.initState();
  }

  Widget _smallHeart() {
    return Icon(
      Icons.favorite,
      color: AppCommonTheme.primaryColor
          .withOpacity(_smallHeartOpacity.value * 0.8),
      size: 12,
    );
  }

  SvgPicture _likeImage(
    Size size,
    String iconName,
    color,
    bool isSmall,
  ) {
    return SvgPicture.asset(
      'assets/images/$iconName.svg',
      color: color,
      width: size.height,
      height: size.width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Text(
          widget.likeCount,
          style: widget.style,
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (context, w) {
            return SizedBox(
              height: 65 * _sizedBoxsize.value,
              width: 65 * _sizedBoxsize.value,
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
                        ? _likeImage(
                            Size(_heartSize.value * 30, _heartSize.value * 30),
                            'like_filled',
                            AppCommonTheme.primaryColor,
                            false,
                          )
                        : _likeImage(
                            Size(_heartSize.value * 30, _heartSize.value * 30),
                            'heart',
                            widget.color,
                            false,
                          ),
                  ),
                  Align(alignment: Alignment.bottomLeft, child: _smallHeart()),
                  Align(alignment: Alignment.topRight, child: _smallHeart()),
                  Align(alignment: Alignment.topLeft, child: _smallHeart()),
                  Align(alignment: Alignment.bottomRight, child: _smallHeart()),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
