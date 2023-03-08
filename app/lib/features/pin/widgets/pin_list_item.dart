import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/utils/utils.dart';
import 'package:effektio/features/pin/pages/pin_item_page.dart';
import 'package:effektio/features/pin/widgets/tag_item.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, ActerPin;
import 'package:flutter/material.dart';

class PinListItem extends StatelessWidget {
  final Client client;
  final ActerPin pin;

  const PinListItem({
    Key? key,
    required this.client,
    required this.pin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return PinItemPage(client: client, pin: pin);
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
                        pin.title(),
                        style: PinTheme.titleStyle,
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
                        border: Border.all(color: PinTheme.supportColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset('assets/images/asakerImage.png'),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Support',
                              style: PinTheme.teamNameStyle,
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
                                "0", //pin.likesCount().toString(),
                                style: PinTheme.likeAndCommentStyle,
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
                                "0", //pin.commentsCount().toString(),
                                style: PinTheme.likeAndCommentStyle,
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
                  child: _TagList(pin: pin),
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
}

class _TagList extends StatelessWidget {
  const _TagList({
    required this.pin,
  });

  final ActerPin pin;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 0, //pin.tags().length,
      itemBuilder: (context, index) {
        // var color = pin.tags().elementAt(index).color();
        // var colorToShow = 0;
        // if (color != null) {
        //   var colorList = color.rgbaU8();
        //   colorToShow = hexOfRGBA(
        //     colorList.elementAt(0),
        //     colorList.elementAt(1),
        //     colorList.elementAt(2),
        //     opacity: 0.7,
        //   );
        // }
        // return TagListItem(
        //   tagTitle: pin.tags().elementAt(index).title(),
        //   tagColor: colorToShow > 0 ? Color(colorToShow) : Colors.white,
        // );
      },
    );
  }
}
