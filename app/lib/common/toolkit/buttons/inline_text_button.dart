import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';

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
    WidgetStatesController? statesController,
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
      child: _IconLabelChild(
        icon: icon,
        label: label,
      ),
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
  final Widget label;
  final Widget icon;

  const _IconLabelChild({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double gap = calcGap(context) ?? 8;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [icon, SizedBox(width: gap), Flexible(child: label)],
    );
  }
}
