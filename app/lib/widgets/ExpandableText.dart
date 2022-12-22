import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  bool isExpanded = false;

  ExpandableText(this.text, {Key? key}) : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText>
    with TickerProviderStateMixin<ExpandableText> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          child: ConstrainedBox(
            constraints: widget.isExpanded
                ? const BoxConstraints()
                : const BoxConstraints(maxHeight: 50.0),
            child: Text(
              widget.text,
              style: ToDoTheme.listSubtitleTextStyle.copyWith(
                color: ToDoTheme.calendarColor,
              ),
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        widget.isExpanded
            ? ConstrainedBox(constraints: const BoxConstraints())
            : GestureDetector(
                child: const Text(
                  'more',
                  style: TextStyle(color: AppCommonTheme.primaryColor),
                ),
                onTap: () => setState(() => widget.isExpanded = true),
              )
      ],
    );
  }
}
