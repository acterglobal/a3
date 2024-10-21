import 'dart:typed_data';

import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::news::image_slide');

class ImageSlide extends StatelessWidget {
  final NewsSlide slide;

  const ImageSlide({
    super.key,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: NewsUpdateKeys.imageUpdateContent,
      child: renderImageContent(),
    );
  }

  Widget renderImageContent() {
    return FutureBuilder<FfiBufferUint8>(
      future: slide.sourceBinary(null),
      builder: (BuildContext context, AsyncSnapshot<FfiBufferUint8> snapshot) {
        final data = snapshot.data;
        final error = snapshot.error;
        if (data != null && snapshot.connectionState == ConnectionState.done) {
          return buildImageUI(data.asTypedList());
        } else if (error != null) {
          return buildImageLoadingErrorUI(context, error, snapshot.stackTrace);
        }
        return buildImageLoadingUI();
      },
    );
  }

  Widget buildImageUI(Uint8List imageData) {
    return Container(
      foregroundDecoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.contain,
          image: MemoryImage(Uint8List.fromList(imageData)),
        ),
      ),
    );
  }

  Widget buildImageLoadingUI() {
    return Center(
      child: Icon(
        PhosphorIcons.image(),
        size: 100,
      ),
    );
  }

  Widget buildImageLoadingErrorUI(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    _log.severe('Failed to load image of slide', error, stackTrace);
    return Center(
      child: Text(L10n.of(context).errorLoadingImage(error)),
    );
  }
}
