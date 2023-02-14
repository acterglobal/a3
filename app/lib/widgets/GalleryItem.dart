import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';

class GalleryItem extends StatelessWidget {
  const GalleryItem({super.key, required this.image});
  final String image;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCommonTheme.textFieldColor,
        borderRadius: BorderRadius.circular(25),
      ),
      width: double.infinity,
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
