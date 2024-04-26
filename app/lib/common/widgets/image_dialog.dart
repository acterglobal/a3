import 'dart:io';
import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zoom_hover_pinch_image/zoom_hover_pinch_image.dart';

class ImageDialog extends ConsumerWidget {
  final String title;
  final File imageFile;

  const ImageDialog({
    super.key,
    required this.title,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Share.shareXFiles([XFile(imageFile.path)]);
                  },
                  icon: const Icon(Icons.share),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Zoom(
                clipBehavior: false,
                width: isDesktop ? width / 3 : width,
                child: Image.file(
                  imageFile,
                  frameBuilder: (
                    BuildContext context,
                    Widget child,
                    int? frame,
                    bool wasSynchronouslyLoaded,
                  ) {
                    if (wasSynchronouslyLoaded) {
                      return child;
                    }
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                  errorBuilder: (
                    BuildContext context,
                    Object url,
                    StackTrace? error,
                  ) {
                    return Text(
                      L10n.of(context).couldNotLoadImage(error.toString()),
                    );
                  },
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
