import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/widgets/custom_avatar.dart';
import 'package:effektio/common/widgets/nav_bar_title.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class SocialProfilePage extends StatefulWidget {
  const SocialProfilePage({Key? key}) : super(key: key);

  @override
  _SocialProfilePageState createState() => _SocialProfilePageState();
}

class _SocialProfilePageState extends State<SocialProfilePage> {
  String? userId;
  Future<FfiBufferUint8>? avatar;
  String? displayName;

  @override
  void initState() {
    super.initState();

    final client = ModalRoute.of(context)!.settings.arguments as Client;
    setState(() => userId = client.userId().toString());
    client.getUserProfile().then((value) {
      if (mounted) {
        setState(() {
          if (value.hasAvatar()) {
            avatar = value.getAvatar();
          }
          displayName = value.getDisplayName();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: navBarTitle('Social Profile'),
        elevation: 1,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Container(
                margin: const EdgeInsets.only(bottom: 10, left: 10),
                child: Image.asset(
                  'assets/images/hamburger.png',
                  color: AppCommonTheme.svgIconColor,
                ),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 10),
              child: Image.asset(
                'assets/images/edit.png',
                color: AppCommonTheme.svgIconColor,
              ),
            ),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  width: double.infinity,
                  height: 230,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      'assets/images/profileBack.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: 50,
                  top: 40,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 100,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(
                              color: AppCommonTheme.primaryColor,
                              width: 5,
                            ),
                          ),
                          child: CustomAvatar(
                            uniqueKey: userId ?? UniqueKey().toString(),
                            avatar: avatar,
                            displayName: displayName,
                            isGroup: false,
                            stringName: ' ',
                            radius: 60,
                          ),
                        ),
                        const Text(
                          'Harjeet kAUR',
                          style: SideMenuAndProfileTheme.profileNameStyle,
                        ),
                        const Text(
                          'Harjeet@gmail.com',
                          style: SideMenuAndProfileTheme.profileUserIdStyle,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 25),
            DefaultTabController(
              length: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const TabBar(
                    tabs: [
                      Tab(
                        child: Text(
                          'News',
                          style: SideMenuAndProfileTheme.profileMenuStyle,
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Feed',
                          style: SideMenuAndProfileTheme.profileMenuStyle,
                        ),
                      ),
                      Tab(
                        child: Text(
                          'More details',
                          style: SideMenuAndProfileTheme.profileMenuStyle,
                        ),
                      ),
                    ],
                    indicatorColor: AppCommonTheme.primaryColor,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 100,
                    child: const TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        Text(''),
                        Text(''),
                        Text(''),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
