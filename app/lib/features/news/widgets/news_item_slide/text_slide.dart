import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextSlide extends ConsumerWidget {
  final NewsSlide slide;
  final Color bgColor;
  final Color fgColor;

  const TextSlide({
    super.key,
    required this.slide,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slideContent = slide.msgContent();
    final formattedText = slideContent.formattedBody();
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: formattedText != null
          ? RenderHtml(
              key: NewsUpdateKeys.textUpdateContent,
              text: formattedText,
              defaultTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: fgColor,
                  ),
            )
          : Text(
              key: NewsUpdateKeys.textUpdateContent,
              slideContent.body(),
              softWrap: true,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: fgColor,
                  ),
            ),
    );
  }
}
