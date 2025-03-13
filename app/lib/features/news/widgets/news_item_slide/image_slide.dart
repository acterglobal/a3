import 'dart:typed_data';

import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/type/update_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/news_media_error_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::news::image_slide');

class ImageSlide extends StatefulWidget {
  final UpdateSlide slide;
  final NewsMediaErrorState errorState; // Add the enum as a parameter

  const ImageSlide({super.key, required this.slide, required this.errorState});

  @override
  State<ImageSlide> createState() => _ImageSlideState();
}

class _ImageSlideState extends State<ImageSlide> {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: UpdateKeys.imageUpdateContent,
      child: renderImageContent(),
    );
  }

  Widget renderImageContent() {
    return FutureBuilder<FfiBufferUint8>(
      future: widget.slide.sourceBinary(null),
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
      key: Key('image_container'),
      foregroundDecoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.contain,
          image: MemoryImage(Uint8List.fromList(imageData)),
        ),
      ),
    );
  }

  Widget buildImageLoadingUI() {
    return Center(child: Icon(PhosphorIcons.image(), size: 100));
  }

  Widget buildImageLoadingErrorUI(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    _log.severe('Failed to load image of slide', error, stackTrace);

    return NewsMediaErrorWidget(
      errorState: widget.errorState,
      onTryAgain: () {
        setState(() {}); // Trigger reload of the image
      },
      mediaType: widget.slide.typeStr(), // Specify it's an image
    );
  }
}
