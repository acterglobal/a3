import 'package:flutter/material.dart';

class PageHeaderWidget extends StatelessWidget {
  final String title;
  final bool? centerTitle;
  final BoxDecoration? sectionDecoration;
  final Widget? expandedContent;
  final double expandedHeight;
  final List<Widget>? actions;

  const PageHeaderWidget({
    Key? key,
    required this.title,
    this.sectionDecoration,
    this.centerTitle = false,
    this.expandedHeight = 120,
    this.actions,
    this.expandedContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      actions: actions,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Container(
            decoration: sectionDecoration,
            child: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 12,
              ),
              centerTitle: centerTitle,
              title: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              background: expandedContent != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              top: 50,
                              right: 50,
                            ),
                            child: expandedContent,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
