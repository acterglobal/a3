import 'package:flutter/material.dart';

class ActerInlineChip extends StatelessWidget {
  final String text;
  final Widget? leading;
  final Widget? trailing;
  final String? tooltip;
  final TextStyle? style;
  final TextStyle? textStyle;
  final BoxDecoration? decoration;
  final VoidCallback? onTap;
  const ActerInlineChip({
    super.key,
    required this.text,
    this.leading,
    this.tooltip,
    this.style,
    this.textStyle,
    this.decoration,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget? child = buildChild(context);

    if (onTap != null) {
      child = InkWell(onTap: onTap, child: child);
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
  }

  Widget buildChild(BuildContext context) {
    final textStyle = this.textStyle ?? Theme.of(context).textTheme.bodySmall;
    final fontSize = textStyle?.fontSize ?? 12.0;
    final icon = leading;
    final end = trailing;
    return Container(
      decoration:
          decoration ??
          BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(fontSize),
          ),
      padding: EdgeInsets.symmetric(
        horizontal: (fontSize / 2).toDouble(),
        vertical: 0,
      ),
      child: RichText(
        text: TextSpan(
          style: textStyle,
          children: [
            if (icon != null)
              WidgetSpan(
                child: Padding(
                  padding: EdgeInsets.only(right: 4, top: 1),
                  child: icon,
                ),
                alignment: PlaceholderAlignment.top,
              ),
            TextSpan(text: text, style: textStyle),
            if (end != null)
              WidgetSpan(
                child: Padding(padding: EdgeInsets.only(left: 4), child: end),
              ),
          ],
        ),
      ),
    );
  }
}
