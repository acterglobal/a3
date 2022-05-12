// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/widget/TagItem.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class FaqItemScreen extends StatefulWidget {
  const FaqItemScreen({Key? key, required this.client, required this.faq})
      : super(key: key);
  final Client client;
  final Faq faq;

  @override
  _FaqItemScreenState createState() => _FaqItemScreenState();
}

TextEditingController _searchController = new TextEditingController();

class _FaqItemScreenState extends State<FaqItemScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.menu),
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
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
                            color: Colors.grey[800],
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
                                  onTap: () => {},
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
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: GestureDetector(
                                    onTap: () => {},
                                    child: Image.asset(
                                      'assets/images/comment.png',
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    widget.faq.commentsCount().toString(),
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 16,
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
                  const Divider(
                    height: 2,
                    thickness: 2,
                    indent: 20,
                    endIndent: 20,
                    color: Colors.grey,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.faq.tags().length,
                        itemBuilder: (context, index) {
                          return TagListItem(
                            tagTitle:
                                widget.faq.tags().elementAt(index).title(),
                          );
                        },
                      ),
                    ),
                  ),
                  const Divider(
                    height: 2,
                    thickness: 2,
                    indent: 20,
                    endIndent: 20,
                    color: Colors.grey,
                  ),
                  Container(),
                ],
              ),
            ),
          ),
          Card(
            color: Colors.grey[800],
            child: Flexible(
              child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 10,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: TextField(
                                    cursorColor: Colors.grey,
                                    decoration: InputDecoration(
                                      hintText: 'Add a comment',
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.emoji_emotions_outlined,
                                      color: Colors.grey),
                                  onPressed: () {
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                    // Your codes...
                                    final snackBar = SnackBar(
                                      content: Text('Emoji icon tapped'),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: SizedBox(
                            width: 30,
                            child: IconButton(
                              onPressed: () {
                                final snackBar = SnackBar(
                                  content: Text('Send icon tapped'),
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              },
                              icon: Icon(
                                Icons.send,
                                color: Colors.pink,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: const [
                        Padding(
                          padding: EdgeInsets.fromLTRB(8.0, 4.0, 4.0, 4.0),
                          child: Text(
                            'Aa',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            'U',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            '@',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.link,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.file_copy,
                          color: Colors.white,
                        ),
                        Icon(Icons.image, color: Colors.white)
                      ],
                    )
                  ],
                ),
              ),
            ),
            shape: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          )
        ],
      ),
    );
  }
}
