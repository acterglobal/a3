
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Faq;
import 'package:effektio/screens/faq/Item.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:themed/themed.dart';

class FaqListItem extends StatefulWidget {
  const FaqListItem({Key? key, required this.client, required this.faq})
      : super(key: key);
  final Client client;
  final Faq faq;

  @override
  FaqListItemState createState() => FaqListItemState();
}

class FaqListItemState extends State<FaqListItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return FaqItemScreen(client: widget.client, faq: widget.faq);
            },
          ),
        );
      },
<<<<<<< HEAD
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.faq.title(),
                        style:FAQTheme.titleStyle,
                      ),
                    ),
                    // new Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => {
                          const SnackBar(
                            content: Text('Bookmark Icon tapped'),
                          )
                        },
                        child: Image.asset(
                                'assets/images/bookmark.png',
                                color: AppCommonTheme.svgIconColor,
                              ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40.0,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(left: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/asakerImage.png',
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: Text(
                              'Support',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              // ignore: avoid_print
                              onTap: () => {print('Heart icon tapped')},
                              child: Image.asset(
                                'assets/images/heart_like.png',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                              ),
                              child: Text(
                                widget.faq.likesCount().toString(),
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: GestureDetector(
                                // ignore: avoid_print
                                onTap: () => {print('Comment icon tapped')},
                                child: Image.asset(
                                  'assets/images/comment.png',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                widget.faq.commentsCount().toString(),
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.faq.tags().length,
                    itemBuilder: (context, index) {
                      var color = widget.faq.tags().elementAt(index).color();
                      var colorToShow = 0;
                      if (color != null) {
                        var colorList = color.rgbaU8();
                        colorToShow = hexOfRGBA(
                          colorList.elementAt(0),
                          colorList.elementAt(1),
                          colorList.elementAt(2),
                          opacity: 0.7,
                        );
                      }

                      return TagListItem(
                        tagTitle: widget.faq.tags().elementAt(index).title(),
                        tagColor: colorToShow > 0
                            ? mColors.Color(colorToShow)
                            : Colors.white,
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ),
        elevation: 8,
        margin: const EdgeInsets.only(top: 20),
        color: AppColors.faqListItemColor,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
=======
      child: Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.faq.title(),
                                style: FAQTheme.titleStyle,
                              ),
                            ),
                            // new Spacer(),
                            GestureDetector(
                              onTap: () => {
                                Fluttertoast.showToast(
                                  msg: 'Bookmark icon tapped',
                                  toastLength: Toast.LENGTH_SHORT,
                                ),
                              },
                              child: Image.asset(
                                'assets/images/bookmark.png',
                                color: AppCommonTheme.svgIconColor,
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 40.0,
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.only(left: 12.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: FAQTheme.faqOutlineBorderColor,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/asakerImage.png',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(
                                      left: 8.0,
                                    ),
                                    child: Text(
                                      'Support',
                                      style: FAQTheme.teameNameStyle,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 40,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => {
                                        Fluttertoast.showToast(
                                          msg: 'Heart icon tapped',
                                          toastLength: Toast.LENGTH_SHORT,
                                        )
                                      },
                                      child: Image.asset(
                                        'assets/images/heart_like.png',
                                        color: AppCommonTheme.svgIconColor,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        left: 8.0,
                                      ),
                                      child: Text(
                                        '189',
                                        style: FAQTheme.likeAndCommentStyle,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: GestureDetector(
                                        onTap: () => {
                                          Fluttertoast.showToast(
                                            msg: 'Comment icon tapped',
                                            toastLength: Toast.LENGTH_SHORT,
                                          )
                                        },
                                        child: Image.asset(
                                          'assets/images/comment.png',
                                          color: AppCommonTheme.svgIconColor,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        '32',
                                        style: FAQTheme.likeAndCommentStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.fromLTRB(
                                4.0,
                                0,
                                4.0,
                                0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: FAQTheme.uxColor,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('UX',
                                      style: FAQTheme.lableStyle +
                                          FAQTheme.uxColor,)
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.fromLTRB(
                                4.0,
                                0,
                                4.0,
                                0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: FAQTheme.importantColor,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Important',
                                    style: FAQTheme.lableStyle +
                                        FAQTheme.importantColor,
                                  )
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.fromLTRB(
                                4.0,
                                0,
                                4.0,
                                0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: FAQTheme.infoColor,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Info',
                                    style: FAQTheme.lableStyle +
                                        FAQTheme.infoColor,
                                  )
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.fromLTRB(
                                4.0,
                                0,
                                4.0,
                                0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: FAQTheme.supportColor,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Support',
                                    style: FAQTheme.lableStyle +
                                        FAQTheme.supportColor,
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                elevation: 8,
                margin: const EdgeInsets.all(20),
                color: FAQTheme.faqCardColor,
                shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: FAQTheme.faqOutlineBorderColor),
                ),
              )
            ],
          ),
          // ),
        ],
>>>>>>> a3294cdc35b5cd197063abbd534652b1f9343557
      ),
    );
  }
}

int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
  r = (r < 0) ? -r : r;
  g = (g < 0) ? -g : g;
  b = (b < 0) ? -b : b;
  opacity = (opacity < 0) ? -opacity : opacity;
  opacity = (opacity > 1) ? 255 : opacity * 255;
  r = (r > 255) ? 255 : r;
  g = (g > 255) ? 255 : g;
  b = (b > 255) ? 255 : b;
  int a = opacity.toInt();
  return int.parse(
    '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}',
  );
}
