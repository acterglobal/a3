import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

/// InlineTextButton for text inlined actions
///
/// This is a TextButton that highlights the given text using the
/// `theme.inlineTextTheme`. Thus this is super useful if you have some text
/// and want a specific part of it to be highlighted to the user indicating
/// it has an action. See [TextButton] for options.
class ActerInlineTextButton extends TextButton {
  const ActerInlineTextButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.clipBehavior = Clip.none,
    super.statesController,
  });

  factory ActerInlineTextButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool? autofocus,
    Clip? clipBehavior,
    MaterialStatesController? statesController,
    required Widget icon,
    required Widget label,
  }) {
    return ActerInlineTextButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus ?? false,
      clipBehavior: clipBehavior = Clip.none,
      statesController: statesController,
      child: _IconLabelChild(icon: icon, label: label),
    );
  }

  @override
  ButtonStyle? themeStyleOf(BuildContext context) {
    return Theme.of(context).inlineTextButtonTheme.style ??
        ElevatedButtonTheme.of(context).style;
  }
}

// copied from the original OutlinedButton
class _IconLabelChild extends StatelessWidget {
  const _IconLabelChild({
    required this.label,
    required this.icon,
  });

  final Widget label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final double scale = MediaQuery.textScalerOf(context).textScaleFactor;
    final double gap =
        scale <= 1 ? 8 : lerpDouble(8, 4, math.min(scale - 1, 1))!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[icon, SizedBox(width: gap), Flexible(child: label)],
    );
  }
}
