import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

const colors = [
  Color(0xffff6767),
  Color(0xff66e0da),
  Color(0xfff5a2d9),
  Color(0xfff0c722),
  Color(0xff6a85e5),
  Color(0xfffd9a6f),
  Color(0xff92db6e),
  Color(0xff73b8e5),
  Color(0xfffd7590),
  Color(0xffc78ae5),
];

Color getUserAvatarNameColor(types.User user, List<Color> colors) =>
    colors[user.id.hashCode % colors.length];

String getUserInitials(types.User user) {
  var initials = '';

  if ((user.firstName ?? '').isNotEmpty) {
    initials += user.firstName![0].toUpperCase();
  }

  if ((user.lastName ?? '').isNotEmpty) {
    initials += user.lastName![0].toUpperCase();
  }

  return initials.trim();
}

class TypeIndicator extends StatefulWidget {
  const TypeIndicator({
    Key? key,
    required this.bubbleAlignment,
    this.options = const TypingIndicatorOptions(),
    required this.showIndicator,
  }) : super(key: key);

  /// See [Message.bubbleRtlAlignment].
  final BubbleRtlAlignment bubbleAlignment;

  /// See [TypingIndicatorOptions].
  final TypingIndicatorOptions options;

  /// Used to hide indicator when the [options.typingUsers] is empty.
  final bool showIndicator;

  @override
  State<TypeIndicator> createState() => _TypeIndicatorState();
}

class _TypeIndicatorState extends State<TypeIndicator>
    with TickerProviderStateMixin {
  late double stackingWidth;
  late AnimationController _appearanceController;
  late AnimationController _animatedCirclesController;
  late Animation<double> _indicatorSpaceAnimation;
  late Animation<Offset> _firstCircleOffsetAnimation;
  late Animation<Offset> _secondCircleOffsetAnimation;
  late Animation<Offset> _thirdCircleOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _indicatorSpaceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    ).drive(
      Tween<double>(
        begin: 0.0,
        end: 60.0,
      ),
    );

    _animatedCirclesController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: widget.options.animationSpeed,
    )..repeat();

    _firstCircleOffsetAnimation = _circleOffset(
      Offset.zero,
      const Offset(0.0, -0.7),
      const Interval(0.0, 0.33, curve: Curves.linear),
    );
    _secondCircleOffsetAnimation = _circleOffset(
      Offset.zero,
      const Offset(0.0, -0.7),
      const Interval(0.28, 0.66, curve: Curves.linear),
    );
    _thirdCircleOffsetAnimation = _circleOffset(
      Offset.zero,
      const Offset(0.0, -0.7),
      const Interval(0.58, 0.99, curve: Curves.linear),
    );

    if (widget.showIndicator) {
      _appearanceController.forward();
    }
  }

  @override
  void didUpdateWidget(TypeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showIndicator != oldWidget.showIndicator) {
      if (widget.showIndicator) {
        _appearanceController.forward();
      } else {
        _appearanceController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _animatedCirclesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _indicatorSpaceAnimation,
        builder: (context, child) => SizedBox(
          height: _indicatorSpaceAnimation.value,
          child: child,
        ),
        child: Row(
          mainAxisAlignment: widget.bubbleAlignment == BubbleRtlAlignment.right
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: <Widget>[
            widget.bubbleAlignment == BubbleRtlAlignment.left
                ? Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: TypingWidget(
                      widget: widget,
                      context: context,
                      mode: widget.options.typingMode,
                    ),
                  )
                : const SizedBox(),
            Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.only(top: 12.0),
              height: 28.0,
              width: 56.0,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(27.0)),
                color: Color(0xFF333540),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 3.0,
                children: <Widget>[
                  AnimatedCircles(
                    circlesColor: const Color(0xFFFFFFFF),
                    animationOffset: _firstCircleOffsetAnimation,
                  ),
                  AnimatedCircles(
                    circlesColor: const Color(0xFFFFFFFF),
                    animationOffset: _secondCircleOffsetAnimation,
                  ),
                  AnimatedCircles(
                    circlesColor: const Color(0xFFFFFFFF),
                    animationOffset: _thirdCircleOffsetAnimation,
                  ),
                ],
              ),
            ),
            widget.bubbleAlignment == BubbleRtlAlignment.right
                ? Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: TypingWidget(
                      widget: widget,
                      context: context,
                      mode: widget.options.typingMode,
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      );

  /// Handler for circles offset.
  Animation<Offset> _circleOffset(
    Offset? start,
    Offset? end,
    Interval animationInterval,
  ) =>
      TweenSequence<Offset>(
        <TweenSequenceItem<Offset>>[
          TweenSequenceItem<Offset>(
            tween: Tween<Offset>(
              begin: start,
              end: end,
            ),
            weight: 50.0,
          ),
          TweenSequenceItem<Offset>(
            tween: Tween<Offset>(
              begin: end,
              end: start,
            ),
            weight: 50.0,
          ),
        ],
      ).animate(
        CurvedAnimation(
          parent: _animatedCirclesController,
          curve: animationInterval,
          reverseCurve: animationInterval,
        ),
      );
}

/// Typing Widget.
class TypingWidget extends StatelessWidget {
  const TypingWidget({
    Key? key,
    required this.widget,
    required this.context,
    required this.mode,
  }) : super(key: key);

  final TypeIndicator widget;
  final BuildContext context;
  final TypingIndicatorMode mode;

  @override
  Widget build(BuildContext context) {
    final sWidth = _getStackingWidth(
      widget.options.typingUsers,
      MediaQuery.of(context).size.width,
    );
    if (mode == TypingIndicatorMode.text) {
      return SizedBox(
        child: Text(
          _multiUserTextBuilder(widget.options.typingUsers),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: neutral2,
          ),
        ),
      );
    } else if (mode == TypingIndicatorMode.avatar) {
      return SizedBox(
        width: sWidth,
        child: AvatarHandler(
          context: context,
          author: widget.options.typingUsers,
        ),
      );
    } else {
      return Row(
        children: <Widget>[
          SizedBox(
            width: sWidth,
            child: AvatarHandler(
              context: context,
              author: widget.options.typingUsers,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _multiUserTextBuilder(widget.options.typingUsers),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: neutral2,
            ),
          ),
        ],
      );
    }
  }

  /// Handler for multi user typing text.
  String _multiUserTextBuilder(List<types.User> author) {
    if (author.isEmpty) {
      return '';
    } else if (author.length == 1) {
      return '${author.first.firstName} is typing...';
    } else if (author.length == 2) {
      return '${author.first.firstName} and ${author[1].firstName} is typing...';
    } else {
      return '${author.first.firstName} and ${author.length - 1} others are typing...';
    }
  }

  /// Used to specify width of stacking avatars based on number of authors.
  double _getStackingWidth(List<types.User> author, double indicatorWidth) {
    if (author.length == 1) {
      return indicatorWidth * 0.06;
    } else if (author.length == 2) {
      return indicatorWidth * 0.11;
    } else {
      return indicatorWidth * 0.15;
    }
  }
}

/// Multi Avatar Handler Widget.
class AvatarHandler extends StatelessWidget {
  const AvatarHandler({
    Key? key,
    required this.context,
    required this.author,
  }) : super(key: key);

  final BuildContext context;
  final List<types.User> author;

  @override
  Widget build(BuildContext context) {
    if (author.isEmpty) {
      return const SizedBox();
    } else if (author.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TypingAvatar(context: context, author: author.first),
      );
    } else if (author.length == 2) {
      return Stack(
        children: <Widget>[
          TypingAvatar(context: context, author: author.first),
          Positioned(
            left: 16,
            child: TypingAvatar(context: context, author: author[1]),
          ),
        ],
      );
    } else {
      return SizedBox(
        child: Stack(
          children: <Widget>[
            TypingAvatar(context: context, author: author.first),
            Positioned(
              left: 16,
              child: TypingAvatar(context: context, author: author[1]),
            ),
            Positioned(
              left: 32,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFFDA88A1),
                child: Text(
                  '${author.length - 2}',
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                  ),
                  textAlign: TextAlign.center,
                  textScaleFactor: 0.7,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// Typing avatar Widget.
class TypingAvatar extends StatelessWidget {
  const TypingAvatar({
    Key? key,
    required this.context,
    required this.author,
  }) : super(key: key);

  final BuildContext context;
  final types.User author;

  @override
  Widget build(BuildContext context) {
    final color = getUserAvatarNameColor(
      author,
      colors,
    );
    final hasImage = author.imageUrl != null;
    final initials = getUserInitials(author);

    return CircleAvatar(
      backgroundColor: color,
      backgroundImage: hasImage ? NetworkImage(author.imageUrl!) : null,
      radius: 13,
      child: !hasImage
          ? Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutral2,
              ),
              textScaleFactor: 0.7,
            )
          : null,
    );
  }
}

/// Animated Circles Widget.
class AnimatedCircles extends StatelessWidget {
  const AnimatedCircles({
    Key? key,
    required this.circlesColor,
    required this.animationOffset,
  }) : super(key: key);

  final Color circlesColor;
  final Animation<Offset> animationOffset;
  @override
  Widget build(BuildContext context) => SlideTransition(
        position: animationOffset,
        child: Container(
          height: 8.0,
          width: 8.0,
          decoration: BoxDecoration(
            color: circlesColor,
            shape: BoxShape.circle,
          ),
        ),
      );
}
