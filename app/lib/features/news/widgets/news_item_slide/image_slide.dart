import 'dart:typed_data';

import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/type/update_slide.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::news::image_slide');

class ImageSlide extends StatefulWidget {
  final UpdateSlide slide;

  const ImageSlide({
    super.key,
    required this.slide,
  });

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.imageBroken(),
            size: 100,
          ),
          SizedBox(height: 10),
          Text(L10n.of(context).unableToLoadImage),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: TextButton(
              onPressed: () => setState(() {}),
              child: Text(L10n.of(context).tryAgain),
            ),
          ),
        ],
      ),
    );
  }
}
