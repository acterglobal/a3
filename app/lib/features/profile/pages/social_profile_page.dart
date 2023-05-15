import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/common/widgets/nav_bar_title.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class SocialProfilePage extends StatefulWidget {
  const SocialProfilePage({Key? key}) : super(key: key);

  @override
  _SocialProfilePageState createState() => _SocialProfilePageState();
}

class _SocialProfilePageState extends State<SocialProfilePage> {
  String? myId;
  Future<FfiBufferUint8>? avatar;
  String? displayName;

  @override
  void initState() {
    super.initState();

    final client = ModalRoute.of(context)!.settings.arguments as Client;
    setState(() => myId = client.userId().toString());
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
        actions: [
          IconButton(
            icon: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 10),
              child: const Icon(Atlas.pencil_edit),
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
                    child: const SizedBox(),
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
                              width: 5,
                            ),
                          ),
                          child: ActerAvatar(
                            mode: DisplayMode.User,
                            uniqueId: myId ?? UniqueKey().toString(),
                            avatarProviderFuture: avatar != null
                                ? remapToImage(
                                    avatar!,
                                    cacheHeight: 200,
                                  )
                                : null,
                            displayName: displayName,
                            size: 60,
                          ),
                        ),
                        const Text(
                          'Harjeet kAUR',
                        ),
                        const Text(
                          'Harjeet@gmail.com',
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
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Feed',
                        ),
                      ),
                      Tab(
                        child: Text(
                          'More details',
                        ),
                      ),
                    ],
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
