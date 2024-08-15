import 'dart:typed_data';

import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::widget::image_slide');

class ImageSlide extends StatelessWidget {
  final NewsSlide slide;
  final Color bgColor;
  final Color fgColor;

  const ImageSlide({
    super.key,
    required this.slide,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiBufferUint8>(
      future: slide.sourceBinary(null),
      builder: (BuildContext context, AsyncSnapshot<FfiBufferUint8> snapshot) {
        if (snapshot.hasError) {
          _log.severe(
            'Failed to load image of slide',
            snapshot.error,
            snapshot.stackTrace,
          );
          return Center(
            child: Text(L10n.of(context).errorLoadingImage(snapshot.error!)),
          );
        }

        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return Container(
            color: bgColor,
            alignment: Alignment.center,
            key: NewsUpdateKeys.imageUpdateContent,
            foregroundDecoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.contain,
                image: MemoryImage(
                  Uint8List.fromList(snapshot.data!.asTypedList()),
                ),
              ),
            ),
          );
        }

        return Center(child: Text(L10n.of(context).loadingImage));
      },
    );
  }
}
