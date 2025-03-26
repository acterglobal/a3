import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/common/themes/acter_theme.dart';

enum TypingIndicatorMode { name, avatar, nameAndAvatar }

enum BubbleRtlAlignment { left, right }

/// Theme for the typing indicator.
class TypingIndicatorTheme {
  const TypingIndicatorTheme({
    this.animatedCircleSize = 5.0,
    this.animatedCirclesColor = Colors.grey,
    this.multipleUserTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.grey,
    ),
  });

  final double animatedCircleSize;
  final Color animatedCirclesColor;
  final TextStyle multipleUserTextStyle;
}

/// Options for the typing indicator.
class TypingIndicatorOptions {
  const TypingIndicatorOptions({
    this.typingUsers = const [],
    this.customTypingWidget,
  });

  final List<AvatarInfo> typingUsers;
  final Widget? customTypingWidget;
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, required this.options});

  final TypingIndicatorOptions options;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> {
  @override
  Widget build(BuildContext context) {
    if (widget.options.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use theme from the context
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final theme = TypingIndicatorTheme(
      animatedCircleSize: 5.0,
      animatedCirclesColor: colorScheme.primary.withAlpha((0.7 * 255).toInt()),
      multipleUserTextStyle:
          textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            fontWeight: FontWeight.w500,
          ) ??
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
    );

    return widget.options.customTypingWidget ??
        TypingWidget(typingUsers: widget.options.typingUsers, theme: theme);
  }
}

/// Typing Widget.
class TypingWidget extends StatelessWidget {
  const TypingWidget({
    super.key,
    required this.typingUsers,
    required this.theme,
  });

  final List<AvatarInfo> typingUsers;
  final TypingIndicatorTheme theme;

  String _buildTypingText(List<AvatarInfo> users, L10n l10n) {
    if (users.isEmpty) return '';
    if (users.length == 1) {
      final name = users.first.displayName;
      return name != null ? l10n.typingUser1(name) : '';
    } else if (users.length == 2) {
      final name1 = users.first.displayName;
      final name2 = users.last.displayName;
      return (name1 != null && name2 != null)
          ? l10n.typingUser2(name1, name2)
          : '';
    } else {
      final name = users.first.displayName;
      return name != null ? l10n.typingUserN(name, users.length - 1) : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    final text = _buildTypingText(typingUsers, l10n);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: theme.multipleUserTextStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 4),
        AnimatedCircles(theme: theme),
      ],
    );
  }
}

/// Multi Avatar Handler Widget.
class AvatarHandler extends StatelessWidget {
  const AvatarHandler({super.key, required this.context, required this.users});

  final BuildContext context;
  final List<AvatarInfo> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const SizedBox();
    } else if (users.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TypingAvatar(context: context, userInfo: users.first),
      );
    } else if (users.length == 2) {
      return Stack(
        children: <Widget>[
          TypingAvatar(context: context, userInfo: users.first),
          Positioned(
            left: 16,
            child: TypingAvatar(context: context, userInfo: users[1]),
          ),
        ],
      );
    } else {
      return SizedBox(
        child: Stack(
          children: <Widget>[
            TypingAvatar(context: context, userInfo: users.first),
            Positioned(
              left: 16,
              child: TypingAvatar(context: context, userInfo: users[1]),
            ),
            Positioned(
              left: 32,
              child: CircleAvatar(
                radius: 13,
                backgroundColor:
                    Theme.of(
                      context,
                    ).chatTheme.typingIndicatorTheme.countAvatarColor,
                child: Text(
                  '${users.length - 2}',
                  style: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).chatTheme.typingIndicatorTheme.countTextColor,
                  ),
                  textAlign: TextAlign.center,
                  textScaler: const TextScaler.linear(0.7),
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
    super.key,
    required this.context,
    required this.userInfo,
  });

  final BuildContext context;
  final AvatarInfo userInfo;

  @override
  Widget build(BuildContext context) {
    return ActerAvatar(options: AvatarOptions.DM(userInfo, size: 26));
  }
}

/// Animated Circles Widget.
class AnimatedCircles extends StatefulWidget {
  const AnimatedCircles({super.key, required this.theme});

  final TypingIndicatorTheme theme;

  @override
  State<AnimatedCircles> createState() => _AnimatedCirclesState();
}

class _AnimatedCirclesState extends State<AnimatedCircles>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _animations = List.generate(
      3,
      (index) =>
          Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.8)).animate(
            CurvedAnimation(
              parent: _controllers[index],
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          ),
    );

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: SlideTransition(
            position: _animations[index],
            child: Container(
              height: widget.theme.animatedCircleSize,
              width: widget.theme.animatedCircleSize,
              decoration: BoxDecoration(
                color: widget.theme.animatedCirclesColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
