import 'dart:typed_data';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ImageSlide extends StatefulWidget {
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
  State<ImageSlide> createState() => _ImageSlideState();
}

class _ImageSlideState extends State<ImageSlide> {
  late Future<FfiBufferUint8> newsImage;
  late MsgContent? msgContent;

  @override
  void initState() {
    super.initState();
    getNewsImage();
  }

  Future<void> getNewsImage() async {
    newsImage = widget.slide.sourceBinary(null);
    msgContent = widget.slide.msgContent();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: newsImage.then((value) => value.asTypedList()),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.hasData) {
          return Container(
            color: widget.bgColor,
            alignment: Alignment.center,
            key: NewsUpdateKeys.imageUpdateContent,
            foregroundDecoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.contain,
                image: MemoryImage(
                  Uint8List.fromList(snapshot.data!),
                ),
              ),
            ),
          );
        } else {
          return Center(child: Text(L10n.of(context).loadingImage));
        }
      },
    );
  }
}
