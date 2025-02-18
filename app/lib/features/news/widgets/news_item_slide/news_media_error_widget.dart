import 'package:acter/common/toolkit/errors/util.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class NewsMediaErrorWidget extends StatelessWidget {
  final NewsMediaErrorState errorState;
  final VoidCallback onTryAgain;
  final String mediaType;

  const NewsMediaErrorWidget({
    super.key,
    required this.errorState,
    required this.onTryAgain,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    Widget errorIcon;
    Widget errorText;

    if (mediaType == 'image') {
      errorIcon = Icon(
        PhosphorIcons.imageBroken(),
        size: 100,
      );
      errorText = Text(
        L10n.of(context).unableToLoadImage,
      );
    } else if(mediaType == 'video'){
      errorIcon = Icon(
        Icons.videocam_off_outlined,
        size: 100,
      );
      errorText = Text(
        L10n.of(context).unableToLoadVideo,
      );
    }else{
      errorIcon = Icon(
        Icons.file_download_off,
        size: 100,
      );
      errorText = Text(
        L10n.of(context).unableToLoadFile,
      );
    }

    // Try again button
    Widget tryAgainButton = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: TextButton(
        onPressed: onTryAgain,
        child: Text(L10n.of(context).tryAgain),
      ),
    );

    switch (errorState) {
      case NewsMediaErrorState.showErrorImageOnly:
        return Center(child: errorIcon);
      case NewsMediaErrorState.showErrorImageWithText:
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
      case NewsMediaErrorState.showErrorWithTryAgain:
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