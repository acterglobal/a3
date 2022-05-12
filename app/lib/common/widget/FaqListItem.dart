import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/TagItem.dart';
import 'package:effektio/screens/faq/Item.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

class FaqListItem extends StatefulWidget {
  const FaqListItem({Key? key, required this.client, required this.faq})
      : super(key: key);
  final Client client;
  final Faq faq;

  @override
  FaqListItemState createState() => FaqListItemState();
}

class FaqListItemState extends State<FaqListItem> {
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, color: Colors.white);

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
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
                              style: GoogleFonts.montserrat(
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
                                style: GoogleFonts.montserrat(
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
                                style: GoogleFonts.montserrat(
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
                      return TagListItem(
                        tagTitle: widget.faq.tags().elementAt(index).title(),
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
      ),
    );
  }
}
