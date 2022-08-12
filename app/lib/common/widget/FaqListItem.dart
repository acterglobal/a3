import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Faq;
import 'package:effektio/screens/faq/Item.dart';

import 'package:effektio/common/widget/TagItem.dart';

class FaqListItem extends StatelessWidget {
  const FaqListItem({Key? key, required this.client, required this.faq})
      : super(key: key);
  final Client client;
  final Faq faq;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return FaqItemScreen(client: client, faq: faq);
            },
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        faq.title(),
                        style: FAQTheme.titleStyle,
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
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: FAQTheme.supportColor,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/asakerImage.png',
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 8, right: 8),
                            child: Text(
                              'Support',
                              style: FAQTheme.teamNameStyle,
                            ),
                          )
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              // ignore: avoid_print
                              onTap: () => {print('Heart icon tapped')},
                              child: Image.asset(
                                'assets/images/heart_like.png',
                                color: AppCommonTheme.svgIconColor,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                              ),
                              child: Text(
                                faq.likesCount().toString(),
                                style: FAQTheme.likeAndCommentStyle,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: GestureDetector(
                                // ignore: avoid_print
                                onTap: () => {print('Comment icon tapped')},
                                child: Image.asset(
                                  'assets/images/comment.png',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                faq.commentsCount().toString(),
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
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: faq.tags().length,
                    itemBuilder: (context, index) {
                      var color = faq.tags().elementAt(index).color();
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
                        tagTitle: faq.tags().elementAt(index).title(),
                        tagColor:
                            colorToShow > 0 ? Color(colorToShow) : Colors.white,
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
        color: FAQTheme.faqCardColor,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
