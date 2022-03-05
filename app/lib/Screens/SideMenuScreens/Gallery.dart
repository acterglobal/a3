import 'package:effektio/Common+Store/Colors.dart';
import 'package:effektio/Common+Widget/AppCommon.dart';
import 'package:effektio/Common+Widget/Feed.dart';
import 'package:flutter/material.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<String> images = [
    'https://cdn.vox-cdn.com/thumbor/xBIBkXiGLcP-kph3pCX61U7RMPY=/0x0:1400x788/1200x800/filters:focal(588x282:812x506)/cdn.vox-cdn.com/uploads/chorus_image/image/70412073/0377c76083423a1414e4001161e0cdffb0b36e1f_760x400.0.png',
    'https://cdn.mos.cms.futurecdn.net/eVyt9jnUrLBSvSwW6pScj9.jpg',
    'https://assets3.thrillist.com/v1/image/3055763/414x310/crop;webp=auto;jpeg_quality=60;progressive.jpg',
    'https://recenthighlights.com/wp-content/uploads/2020/06/Solo-Leveling-Anime.jpg',
    'https://i.ytimg.com/vi/dWnhkEFRzFQ/maxresdefault.jpg',
    'https://i.ytimg.com/vi/dWnhkEFRzFQ/maxresdefault.jpg',
    'https://recenthighlights.com/wp-content/uploads/2020/06/Solo-Leveling-Anime.jpg',
    'https://cdn.mos.cms.futurecdn.net/eVyt9jnUrLBSvSwW6pScj9.jpg',
    '',
    'https://assets3.thrillist.com/v1/image/3055763/414x310/crop;webp=auto;jpeg_quality=60;progressive.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.textFieldColor,
        title: navBarTitle('Gallery'),
      ),
      backgroundColor: Colors.black,
      body: Container(
        margin: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: List.generate(10, (index) {
            return Center(
              child: galleryImagesView(images[index]),
            );
          }),
        ),
      ),
    );
  }
}
