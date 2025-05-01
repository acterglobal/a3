import 'package:acter/features/chat_ng/providers/chat_typing_event_providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Typing Widget.
class TypingIndicator extends ConsumerWidget {
  static const typingRendererKey = Key('typing_widget_renderer');
  const TypingIndicator({super.key, required this.roomId});

  final String roomId;

  String _buildTypingText(WidgetRef ref, L10n l10n) {
    final displayNamesList = ref.watch(
      chatTypingUsersDisplayNameProvider(roomId),
    );
    if (displayNamesList.isEmpty) return '';
    if (displayNamesList.length == 1) {
      final name = displayNamesList.first;
      return l10n.typingUser1(name);
    } else if (displayNamesList.length == 2) {
      final name1 = displayNamesList.first;
      final name2 = displayNamesList.last;
      return l10n.typingUser2(name1, name2);
    } else {
      final name = displayNamesList.first;
      return l10n.typingUserN(name, displayNamesList.length - 1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).typingIndicatorTheme;
    if (ref.watch(chatTypingEventProvider(roomId)).valueOrNull?.isEmpty ==
        true) {
      return const SizedBox.shrink();
    }

    return Row(
      key: TypingIndicator.typingRendererKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarHandler(
          users: ref.watch(chatTypingUsersAvatarInfoProvider(roomId)),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            _buildTypingText(ref, l10n),
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
        child: ActerAvatar(options: AvatarOptions.DM(users.first, size: 12)),
      );
    } else if (users.length == 2) {
      return SizedBox(
        width: 44,
        child: Stack(
          children: <Widget>[
            ActerAvatar(options: AvatarOptions.DM(users.first, size: 12)),
            Positioned(
              left: isRtl ? null : 16,
              right: isRtl ? 16 : null,
              child: ActerAvatar(options: AvatarOptions.DM(users[1], size: 12)),
            ),
          ],
        ),
      );
    } else {
      return SizedBox(
        width: 58,
        child: Stack(
          children: <Widget>[
            ActerAvatar(options: AvatarOptions.DM(users.first, size: 12)),
            Positioned(
              left: isRtl ? null : 16,
              right: isRtl ? 16 : null,
              child: ActerAvatar(options: AvatarOptions.DM(users[1], size: 12)),
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
