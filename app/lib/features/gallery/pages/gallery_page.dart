import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/widgets/gallery_item.dart';
import 'package:effektio/common/widgets/nav_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppCommonTheme.textFieldColor,
        title: navBarTitle(AppLocalizations.of(context)!.gallery),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Container(
        margin: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: List.generate(9, (int index) {
            return Center(
              child: GalleryItem(image: images[index]),
            );
          }),
        ),
      ),
    );
  }
}
