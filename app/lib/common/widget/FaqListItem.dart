import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/store/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Faq;
import 'package:effektio/screens/faq/Item.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    final _textTheme = Theme.of(context).textTheme;
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
                                style: _textTheme.titleSmall,
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
                                color: isDarkTheme
                                    ? AppColors.lightIconColor
                                    : AppColors.darkIconColor,
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
                                  color: !isDarkTheme
                                      ? AppColors.primaryColor
                                      : AppColors.lightBackgroundColor,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/asakerImage.png',
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                    ),
                                    child: Text(
                                      'Support',
                                      style: _textTheme.titleSmall,
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
                                        color: isDarkTheme
                                            ? AppColors.lightIconColor
                                            : AppColors.darkIconColor,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8.0,
                                      ),
                                      child: Text(
                                        '189',
                                        style: _textTheme.labelLarge,
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
                                          color: isDarkTheme
                                              ? AppColors.lightIconColor
                                              : AppColors.darkIconColor,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        '32',
                                        style: _textTheme.labelLarge,
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
                                  color: const Color(0xFF7879F1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UX',
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFF7879F1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                  color: const Color(0xFF23AFC2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Important',
                                    style: _textTheme.bodySmall,
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
                                  color: const Color(0xFFFA8E10),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Info',
                                    style: _textTheme.bodySmall,
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
                                  color: const Color(0xFFB8FFDD),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Support',
                                    style: _textTheme.bodySmall,
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
                color: isDarkTheme
                    ? AppColors.darkFaqCardColor
                    : AppColors.lightFaqCardColor,
                shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.dividerColor),
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
