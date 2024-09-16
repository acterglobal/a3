import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextSlide extends ConsumerStatefulWidget {
  final NewsSlide slide;
  final Color bgColor;
  final Color fgColor;
  final PageController pageController;

  const TextSlide({
    super.key,
    required this.slide,
    required this.bgColor,
    required this.fgColor,
    required this.pageController,
  });

  @override
  ConsumerState<TextSlide> createState() => _TextSlideState();
}

class _TextSlideState extends ConsumerState<TextSlide> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final topPosition = _scrollController.position.pixels <= 0;
    final outOfRange = _scrollController.position.outOfRange;
    final offset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (topPosition && outOfRange && offset < -150) {
      widget.pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else if (!topPosition && outOfRange && offset > maxScrollExtent + 150) {
      widget.pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slideContent = widget.slide.msgContent();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 70),
      color: widget.bgColor,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 100),
        // SelectionArea and SelectableText for select text
        child: slideContent.formattedBody().let(
                  (p0) => SelectionArea(
                    child: RenderHtml(
                      key: NewsUpdateKeys.textUpdateContent,
                      text: p0,
                      defaultTextStyle:
                          Theme.of(context).textTheme.bodyLarge!.copyWith(
                                color: widget.fgColor,
                              ),
                    ),
                  ),
                ) ??
            SelectableText(
              key: NewsUpdateKeys.textUpdateContent,
              slideContent.body(),
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: widget.fgColor,
                  ),
            ),
      ),
    );
  }
}
