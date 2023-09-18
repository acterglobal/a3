import 'package:flutter/material.dart';

class PageHeaderWidget extends StatelessWidget {
  final String title;
  final Color sectionColor;
  final Color? gradientBottom;
  final Widget? expandedContent;
  final double expandedHeight;
  final List<Widget>? actions;

  const PageHeaderWidget({
    Key? key,
    required this.title,
    required this.sectionColor,
    this.gradientBottom,
    this.expandedHeight = 160,
    this.actions,
    this.expandedContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: sectionColor,
      pinned: true,
      expandedHeight: expandedHeight,
      title: Text(title),
      actions: actions,
      flexibleSpace: expandedContent != null
          ? SizedBox.expand(
              child: Container(
                decoration: BoxDecoration(
                  color: sectionColor,
                  gradient: LinearGradient(
                    begin: FractionalOffset.topCenter,
                    end: FractionalOffset.bottomCenter,
                    colors: [
                      sectionColor,
                      gradientBottom ?? Theme.of(context).canvasColor,
                    ],
                    stops: const [0, 1],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: expandedContent!,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
