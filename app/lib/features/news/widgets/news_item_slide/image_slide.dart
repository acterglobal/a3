import 'dart:typed_data';

import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::news::image_slide');

class ImageSlide extends StatefulWidget {
  final NewsSlide slide;
  final NewsLoadingState errorState;  // Add the enum as a parameter

  const ImageSlide({
    super.key,
    required this.slide,
    required this.errorState,
  });

  @override
  State<ImageSlide> createState() => _ImageSlideState();
}

class _ImageSlideState extends State<ImageSlide> {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: NewsUpdateKeys.imageUpdateContent,
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

    Widget errorIcon = Icon(
      PhosphorIcons.imageBroken(),
      size: 100,
    );

    Widget errorText = Text(
      L10n.of(context).unableToLoadImage,
    );

    Widget tryAgainButton = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: TextButton(
        onPressed: () {
          setState(() {}); // Trigger reload of the image
        },
        child: Text(L10n.of(context).tryAgain,),
      ),
    );

    switch (widget.errorState) {
      case NewsLoadingState.showErrorImageOnly:
        return Center(child: errorIcon);
      case NewsLoadingState.showErrorImageWithText:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              errorIcon,
              SizedBox(height: 10),
              errorText,
            ],
          ),
        );
      case NewsLoadingState.showErrorWithTryAgain:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              errorIcon,
              SizedBox(height: 10),
              errorText,
              SizedBox(height: 20),
              tryAgainButton,
            ],
          ),
        );
    }
  }
}
