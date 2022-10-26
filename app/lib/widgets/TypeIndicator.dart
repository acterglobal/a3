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
  /// See [Message.bubbleRtlAlignment].
  final BubbleRtlAlignment bubbleAlignment;

  /// See [TypingIndicatorOptions].
  final TypingIndicatorOptions options;

  /// Used to hide indicator when the [options.typingUsers] is empty.
  final bool showIndicator;

  const TypeIndicator({
    Key? key,
    required this.bubbleAlignment,
    this.options = const TypingIndicatorOptions(),
    required this.showIndicator,
  }) : super(key: key);

  @override
  State<TypeIndicator> createState() => _TypeIndicatorState();
}

class _TypeIndicatorState extends State<TypeIndicator>
    with TickerProviderStateMixin {
  late AnimationController appearanceController;
  late AnimationController bubblesController;
  late Animation<double> indicatorSpaceAnimation;
  late Animation<Offset> firstBubbleOffsetAnimation;
  late Animation<Offset> secondBubbleOffsetAnimation;
  late Animation<Offset> thirdBubbleOffsetAnimation;

  @override
  void initState() {
    super.initState();

    appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    indicatorSpaceAnimation = CurvedAnimation(
      parent: appearanceController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    ).drive(
      Tween<double>(begin: 0.0, end: 60.0),
    );

    bubblesController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: widget.options.animationSpeed,
    )..repeat();

    firstBubbleOffsetAnimation = getBubbleOffsetAnimation(
      Offset.zero,
      const Offset(0.0, -0.7),
      const Interval(0.0, 0.33, curve: Curves.linear),
    );
    secondBubbleOffsetAnimation = getBubbleOffsetAnimation(
      Offset.zero,
      const Offset(0.0, -0.7),
      const Interval(0.28, 0.66, curve: Curves.linear),
    );
    thirdBubbleOffsetAnimation = getBubbleOffsetAnimation(
      Offset.zero,
      const Offset(0.0, -0.7),
      const Interval(0.58, 0.99, curve: Curves.linear),
    );

    if (widget.showIndicator) {
      appearanceController.forward();
    }
  }

  @override
  void didUpdateWidget(TypeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showIndicator != oldWidget.showIndicator) {
      if (widget.showIndicator) {
        appearanceController.forward();
      } else {
        appearanceController.reverse();
      }
    }
  }

  @override
  void dispose() {
    appearanceController.dispose();
    bubblesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: indicatorSpaceAnimation,
      builder: (context, child) => SizedBox(
        height: indicatorSpaceAnimation.value,
        child: child,
      ),
      child: Row(
        mainAxisAlignment: widget.bubbleAlignment == BubbleRtlAlignment.right
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (widget.bubbleAlignment == BubbleRtlAlignment.left) buildStart(),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.only(top: 12),
            height: 28,
            width: 56,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(27)),
              color: Color(0xFF333540),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 3,
              children: [
                AnimatedBubble(
                  color: const Color(0xFFFFFFFF),
                  animationOffset: firstBubbleOffsetAnimation,
                ),
                AnimatedBubble(
                  color: const Color(0xFFFFFFFF),
                  animationOffset: secondBubbleOffsetAnimation,
                ),
                AnimatedBubble(
                  color: const Color(0xFFFFFFFF),
                  animationOffset: thirdBubbleOffsetAnimation,
                ),
              ],
            ),
          ),
          if (widget.bubbleAlignment == BubbleRtlAlignment.right) buildEnd(),
        ],
      ),
    );
  }

  Widget buildStart() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: TypingWidget(
        widget: widget,
        mode: widget.options.typingMode,
      ),
    );
  }

  Widget buildEnd() {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: TypingWidget(
        widget: widget,
        mode: widget.options.typingMode,
      ),
    );
  }

  /// Handler for circles offset.
  Animation<Offset> getBubbleOffsetAnimation(
    Offset? begin,
    Offset? end,
    Interval animationInterval,
  ) {
    return TweenSequence<Offset>(
      <TweenSequenceItem<Offset>>[
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(begin: begin, end: end),
          weight: 50.0,
        ),
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(begin: end, end: begin),
          weight: 50.0,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: bubblesController,
        curve: animationInterval,
        reverseCurve: animationInterval,
      ),
    );
  }
}

/// Typing Widget.
class TypingWidget extends StatelessWidget {
  final TypeIndicator widget;
  final TypingIndicatorMode mode;

  const TypingWidget({
    Key? key,
    required this.widget,
    required this.mode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sWidth = _getStackingWidth(
      widget.options.typingUsers,
      MediaQuery.of(context).size.width,
    );
    if (mode == TypingIndicatorMode.text) {
      return SizedBox(
        child: Text(
          _getUserPlural(widget.options.typingUsers),
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
        child: AvatarHandler(authors: widget.options.typingUsers),
      );
    } else {
      return Row(
        children: <Widget>[
          SizedBox(
            width: sWidth,
            child: AvatarHandler(authors: widget.options.typingUsers),
          ),
          const SizedBox(width: 10),
          Text(
            _getUserPlural(widget.options.typingUsers),
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

  /// Used to specify width of stacking avatars based on number of authors.
  double _getStackingWidth(List<types.User> authors, double indicatorWidth) {
    if (authors.length == 1) {
      return indicatorWidth * 0.06;
    } else if (authors.length == 2) {
      return indicatorWidth * 0.11;
    } else {
      return indicatorWidth * 0.15;
    }
  }

  /// Handler for multi user typing text.
  String _getUserPlural(List<types.User> authors) {
    if (authors.isEmpty) {
      return '';
    } else if (authors.length == 1) {
      return '${authors[0].firstName} is typing...';
    } else if (authors.length == 2) {
      return '${authors[0].firstName} and ${authors[1].firstName} is typing...';
    } else {
      return '${authors[0].firstName} and ${authors.length - 1} others are typing...';
    }
  }
}

/// Multi Avatar Handler Widget.
class AvatarHandler extends StatelessWidget {
  final List<types.User> authors;

  const AvatarHandler({Key? key, required this.authors}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) {
      return const SizedBox();
    } else if (authors.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TypingAvatar(author: authors[0]),
      );
    } else if (authors.length == 2) {
      return Stack(
        children: [
          TypingAvatar(author: authors[0]),
          Positioned(
            left: 16,
            child: TypingAvatar(author: authors[1]),
          ),
        ],
      );
    } else {
      return SizedBox(
        child: Stack(
          children: <Widget>[
            TypingAvatar(author: authors[0]),
            Positioned(
              left: 16,
              child: TypingAvatar(author: authors[1]),
            ),
            Positioned(
              left: 32,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFFDA88A1),
                child: Text(
                  '${authors.length - 2}',
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
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
  final types.User author;

  const TypingAvatar({Key? key, required this.author}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: getUserAvatarNameColor(author, colors),
      backgroundImage: _buildImage(),
      radius: 13,
      child: _buildInitials(),
    );
  }

  ImageProvider<Object>? _buildImage() {
    if (author.imageUrl == null) {
      return null;
    }
    return NetworkImage(author.imageUrl!);
  }

  Widget? _buildInitials() {
    if (author.imageUrl != null) {
      return null;
    }
    return Text(
      getUserInitials(author),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: neutral2,
      ),
      textScaleFactor: 0.7,
    );
  }
}

/// Animated Circles Widget.
class AnimatedBubble extends StatelessWidget {
  final Color color;
  final Animation<Offset> animationOffset;

  const AnimatedBubble({
    Key? key,
    required this.color,
    required this.animationOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animationOffset,
      child: Container(
        height: 8.0,
        width: 8.0,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
