import 'package:effektio/common/animations/LikeAnimation.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/network_controller.dart';
import 'package:effektio/widgets/NewsItem.dart';
import 'package:effektio/widgets/NoInternet.dart';
import 'package:effektio/widgets/SideMenu.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewsScreen extends StatefulWidget {
  final Client client;
  final String? displayName;
  final Future<FfiBufferUint8>? displayAvatar;

  const NewsScreen({
    Key? key,
    required this.client,
    this.displayName,
    this.displayAvatar,
  }) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  final networkController = Get.put(NetworkController());

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListNews>(
      future: widget.client.latestNews(),
      builder: (BuildContext context, AsyncSnapshot<FfiListNews> snapshot) {
        return Obx(
          () => Container(
            child: networkController.connectionType.value == '0'
                ? noInternetWidget()
                : (!snapshot.hasData)
                    ? SizedBox(
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
                      )
                    : Scaffold(
                        extendBodyBehindAppBar: true,
                        appBar: AppBar(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          leading: Builder(
                            builder: (BuildContext context) {
                              return IconButton(
                                icon: Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 10,
                                    left: 10,
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor:
                                        AppCommonTheme.primaryColor,
                                    child: Image.asset(
                                        'assets/images/hamburger.png'),
                                  ),
                                ),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                tooltip: MaterialLocalizations.of(context)
                                    .openAppDrawerTooltip,
                              );
                            },
                          ),
                          centerTitle: true,
                          title: const ButtonBar(
                            alignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'All',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  shadows: <Shadow>[
                                    Shadow(
                                      blurRadius: 1.0,
                                      color: Colors.black,
                                    ),
                                  ],
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                              Text(
                                'News',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  shadows: <Shadow>[
                                    Shadow(
                                      blurRadius: 5.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      blurRadius: 3.0,
                                      color: Colors.black,
                                    ),
                                  ],
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Stories',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  shadows: <Shadow>[
                                    Shadow(
                                      blurRadius: 1.0,
                                      color: Colors.black,
                                    ),
                                  ],
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                            ],
                          ),
                        ),
                        drawer: SideDrawer(
                          isGuest: widget.client.isGuest(),
                          userId: widget.client.userId().toString(),
                          displayName: widget.displayName,
                          displayAvatar: widget.displayAvatar,
                        ),
                        body: PageView.builder(
                          itemCount: snapshot.requireData.length,
                          onPageChanged: (int page) {},
                          scrollDirection: Axis.vertical,
                          itemBuilder: (context, index) => InkWell(
                            onDoubleTap: () {
                              LikeAnimation.run(index);
                            },
                            child: NewsItem(
                              client: widget.client,
                              news: snapshot.requireData[index],
                              index: index,
                            ),
                          ),
                        ),
                      ),
          ),
        );
      },
    );
  }
}
