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
        child: Column(
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
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
                                GestureDetector(
                                  onTap: () => {
                                    Fluttertoast.showToast(
                                      msg: 'Bookmark icon tapped',
                                      toastLength: Toast.LENGTH_SHORT,
                                    ),
                                  },
                                  child: Image.asset(
                                    'assets/images/bookmark.png',
                                  ),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 40.0,
                                  padding: EdgeInsets.all(8.0),
                                  margin: EdgeInsets.only(left: 12.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Color(0XFFFFFFFFF),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                new Spacer(),
                                Container(
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
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: Text(
                                            '189',
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: GestureDetector(
                                            onTap: () => {
                                              Fluttertoast.showToast(
                                                msg: 'Comment icon tapped',
                                                toastLength: Toast.LENGTH_SHORT,
                                              )
                                            },
                                            child: Image.asset(
                                              'assets/images/comment.png',
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            '32',
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
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  margin: EdgeInsets.fromLTRB(
                                    4.0,
                                    0,
                                    4.0,
                                    0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Color(0xFF7879F1),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'UX',
                                        style: GoogleFonts.montserrat(
                                          color: Color(0xFF7879F1),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  margin: EdgeInsets.fromLTRB(
                                    4.0,
                                    0,
                                    4.0,
                                    0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Color(0xFF23AFC2),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Important',
                                        style: GoogleFonts.montserrat(
                                          color: Color(0xFF23AFC2),
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  margin: EdgeInsets.fromLTRB(
                                    4.0,
                                    0,
                                    4.0,
                                    0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Color(0xFFFA8E10),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Info',
                                        style: GoogleFonts.montserrat(
                                          color: Color(0xFFFA8E10),
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  margin: EdgeInsets.fromLTRB(
                                    4.0,
                                    0,
                                    4.0,
                                    0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Color(0xFFB8FFDD),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Support',
                                        style: GoogleFonts.montserrat(
                                          color: Color(0xFFB8FFDD),
                                          fontSize: 12,
                                        ),
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
                    margin: EdgeInsets.all(20),
                    color: Color(0xFF2F313E),
                    shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF2F313E)),
                    ),
                  ),
                )
              ],
            ),
            // ),
          ],
        ));
  }
}
