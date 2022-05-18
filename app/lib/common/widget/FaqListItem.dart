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
      ),
    );
  }
}
