// ignore_for_file: prefer_const_constructors

import 'package:effektio/blocs/like_animation.dart';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/NewsItem.dart';
import 'package:effektio/common/widget/SideMenu.dart';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key, required this.client}) : super(key: key);
  final Client client;

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with TickerProviderStateMixin {
  late AnimationController controller;
  @override
  void initState() {
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListNews>(
      future: widget.client.latestNews(),
      builder: (BuildContext context, AsyncSnapshot<FfiListNews> snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: AppCommonTheme.primaryColor,
                ),
              ),
            ),
          );
        } else {
          //final items = snapshot.requireData.toList();
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: Container(
                      margin: const EdgeInsets.only(bottom: 10, left: 10),
                      child: CircleAvatar(
                        backgroundColor: AppCommonTheme.primaryColor,
                        child: Image.asset('assets/images/hamburger.png'),
                      ),
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip:
                        MaterialLocalizations.of(context).openAppDrawerTooltip,
                  );
                },
              ),
            ),
            drawer: SideDrawer(
              client: Future.value(widget.client),
            ),
            body: PageView.builder(
              itemCount: snapshot.requireData.length,
              onPageChanged: (int page) {},
              scrollDirection: Axis.vertical,
              itemBuilder: ((context, index) {
                return InkWell(
                  onDoubleTap: (() {
                    LikeAnimation.run(index);
                  }),
                  child: NewsItem(
                    client: widget.client,
                    news: snapshot.requireData[index],
                    index: index,
                  ),
                );
              }),
            ),
          );
        }
      },
    );
  }
}
