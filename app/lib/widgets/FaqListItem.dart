import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/screens/HomeScreens/faq/Item.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/TagItem.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Faq;
import 'package:flutter/material.dart';

class FaqListItem extends StatelessWidget {
  final Client client;
  final Faq faq;

  const FaqListItem({
    Key? key,
    required this.client,
    required this.faq,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return FaqItemScreen(client: client, faq: faq);
            },
          ),
        );
      },
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        faq.title(),
                        style: FAQTheme.titleStyle,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => {
                        const SnackBar(content: Text('Bookmark Icon tapped'))
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
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                        border: Border.all(color: FAQTheme.supportColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset('assets/images/asakerImage.png'),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
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
                              onTap: () => debugPrint('Heart icon tapped'),
                              child: Image.asset(
                                'assets/images/heart_like.png',
                                color: AppCommonTheme.svgIconColor,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                faq.likesCount().toString(),
                                style: FAQTheme.likeAndCommentStyle,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: GestureDetector(
                                onTap: () => debugPrint('Comment icon tapped'),
                                child: Image.asset('assets/images/comment.png'),
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: 40,
                  child: _buildTagList(),
                ),
              )
            ],
          ),
        ),
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: PinsTheme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildTagList() {
    return ListView.builder(
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
          tagColor: colorToShow > 0 ? Color(colorToShow) : Colors.white,
        );
      },
    );
  }
}
