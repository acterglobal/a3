// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/NewsItem.dart';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key, required this.client}) : super(key: key);
  final Client client;

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListNews>(
        future: widget.client.latestNews(),
        builder: (BuildContext context, AsyncSnapshot<FfiListNews> snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: AppColors.backgroundColor,
              child: Center(
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
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
                      tooltip: MaterialLocalizations.of(context)
                          .openAppDrawerTooltip,
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
                  return NewsItem(
                      client: widget.client, news: snapshot.requireData[index]);
                }),
              ),
            );
          }
        });
  }
}
