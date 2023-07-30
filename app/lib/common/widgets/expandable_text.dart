// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  bool isExpanded = false;

  ExpandableText(this.text, {Key? key}) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
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
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        widget.isExpanded
            ? ConstrainedBox(constraints: const BoxConstraints())
            : GestureDetector(
                onTap: onClickMore,
                child: const Text('more'),
              )
      ],
    );
  }

  void onClickMore() {
    if (mounted) {
      setState(() => widget.isExpanded = true);
    }
  }
}
