import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class TypingIndicator extends ConsumerWidget {
  const TypingIndicator({super.key, required this.typingUsers});

  final List<AvatarInfo> typingUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).typingIndicatorTheme;

    return TypingWidget(typingUsers: typingUsers, theme: theme);
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
      final name = users.first.displayName ?? users.first.uniqueId;
      return l10n.typingUser1(name);
    } else if (users.length == 2) {
      final name1 = users.first.displayName ?? users.first.uniqueId;
      final name2 = users.last.displayName ?? users.last.uniqueId;
      return l10n.typingUser2(name1, name2);
    } else {
      final name = users.first.displayName ?? users.first.uniqueId;
      return l10n.typingUserN(name, users.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final text = _buildTypingText(typingUsers, l10n);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarHandler(users: typingUsers),
        const SizedBox(width: 4),
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
  const AvatarHandler({super.key, required this.users});

  final List<AvatarInfo> users;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (users.isEmpty) {
      return const SizedBox();
    } else if (users.length == 1) {
      return Align(
        alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
        child: TypingAvatar(context: context, userInfo: users.first),
      );
    } else if (users.length == 2) {
      return SizedBox(
        width: 44,
        child: Stack(
          children: <Widget>[
            TypingAvatar(context: context, userInfo: users.first),
            Positioned(
              left: isRtl ? null : 16,
              right: isRtl ? 16 : null,
              child: TypingAvatar(context: context, userInfo: users[1]),
            ),
          ],
        ),
      );
    } else {
      return SizedBox(
        width: 58,
        child: Stack(
          children: <Widget>[
            TypingAvatar(context: context, userInfo: users.first),
            Positioned(
              left: isRtl ? null : 16,
              right: isRtl ? 16 : null,
              child: TypingAvatar(context: context, userInfo: users[1]),
            ),
            Positioned(
              left: isRtl ? null : 32,
              right: isRtl ? 32 : null,
              child: CircleAvatar(
                radius: 12,
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
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
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
    return ActerAvatar(options: AvatarOptions.DM(userInfo, size: 12));
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
  final List<Timer> _timers = [];

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
    startAnimations();
  }

  void startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      final timer = Timer(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
      _timers.add(timer);
    }
  }

  @override
  void dispose() {
    // Cancel any pending timers
    for (final timer in _timers) {
      timer.cancel();
    }

    // Dispose animation controllers
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
