// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/NewsItem.dart';
import 'package:effektio/common/widget/SideMenu.dart';
<<<<<<< HEAD
=======

>>>>>>> a3294cdc35b5cd197063abbd534652b1f9343557
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key, required this.client}) : super(key: key);
  final Client client;

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListNews>(
      future: widget.client.latestNews(),
      builder: (BuildContext context, AsyncSnapshot<FfiListNews> snapshot) {
        if (!snapshot.hasData) {
<<<<<<< HEAD
          return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: AppColors.backgroundColor,
=======
          return SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
>>>>>>> a3294cdc35b5cd197063abbd534652b1f9343557
            child: Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
<<<<<<< HEAD
                  color: AppColors.primaryColor,
=======
                  color: AppCommonTheme.primaryColor,
>>>>>>> a3294cdc35b5cd197063abbd534652b1f9343557
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
<<<<<<< HEAD
              backgroundColor: Colors.transparent,
=======
>>>>>>> a3294cdc35b5cd197063abbd534652b1f9343557
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: Container(
                      margin: const EdgeInsets.only(bottom: 10, left: 10),
<<<<<<< HEAD
                      child: Image.asset('assets/images/hamburger.png'),
=======
                      child: CircleAvatar(
                        backgroundColor: AppCommonTheme.primaryColor,
                        child: Image.asset('assets/images/hamburger.png'),
                      ),
>>>>>>> a3294cdc35b5cd197063abbd534652b1f9343557
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
                return NewsItem(
                  client: widget.client,
                  news: snapshot.requireData[index],
                );
              }),
            ),
          );
        }
      },
    );
  }
}
