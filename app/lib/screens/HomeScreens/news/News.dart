import 'package:effektio/common/animations/LikeAnimation.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/widgets/NewsItem.dart';
import 'package:effektio/widgets/SideMenu.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  final Client client;

  const NewsScreen({Key? key, required this.client}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
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
            child: const Center(
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
            drawer: SideDrawer(client: widget.client),
            body: PageView.builder(
              itemCount: snapshot.requireData.length,
              onPageChanged: (int page) {},
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) => InkWell(
                onDoubleTap: (() {
                  LikeAnimation.run(index);
                }),
                child: NewsItem(
                  client: widget.client,
                  news: snapshot.requireData[index],
                  index: index,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
