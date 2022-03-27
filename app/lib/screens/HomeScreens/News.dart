// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/widget/FeedDetail.dart';
import 'package:effektio/common/widget/NewsSideBar.dart';
import 'package:effektio/common/widget/SideMenu.dart';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key, required this.client}) : super(key: key);
  final Future<Client> client;

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Container(
                margin: const EdgeInsets.only(bottom: 10, left: 10),
                child: Image.asset('assets/images/hamburger.png'),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      drawer: SideDrawer(
        client: widget.client,
      ),
      body: PageView.builder(
        itemCount: feeds.length,
        onPageChanged: (int page) {},
        scrollDirection: Axis.vertical,
        itemBuilder: ((context, index) {
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: feeds[index],
                  clipBehavior: Clip.none,
                ),
              ),
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
                      child: FeedDetail(),
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
        }),
      ),
    );
  }
}
