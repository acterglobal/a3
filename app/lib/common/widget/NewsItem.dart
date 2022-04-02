import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './NewsSideBar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

class NewsItem extends StatefulWidget {
  const NewsItem({Key? key, required this.client, required this.news})
      : super(key: key);
  final Client client;
  final News news;

  @override
  _NewsItemState createState() => _NewsItemState();
}

class _NewsItemState extends State<NewsItem> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Expanded(
        //   child: Container(
        //     width: MediaQuery.of(context).size.width,
        //     height: MediaQuery.of(context).size.height,
        //     child: snapshot.requireData[index],
        //     clipBehavior: Clip.none,
        //   ),
        // ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              flex: 3,
              // ignore: sized_box_for_whitespace
              child: Container(
                decoration: BoxDecoration(
                  // ignore: prefer_const_literals_to_create_immutables
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20.0,
                      spreadRadius: 100,
                      offset: Offset(0.0, 200.0),
                    ),
                  ],
                ),
                height: MediaQuery.of(context).size.height / 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Lorem Ipsum is simply dummy text of the printing and',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // ignore: prefer_const_constructors
                      SizedBox(height: 10),
                      // ignore: prefer_const_constructors
                      Text(
                        widget.news.text() ?? "",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              // ignore: sized_box_for_whitespace
              child: Container(
                height: MediaQuery.of(context).size.height / 2.5,
                child: NewsSideBar(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
