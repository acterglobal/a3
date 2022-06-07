// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/customAvatar.dart';
import 'package:effektio/screens/UserScreens/SocialProfile.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' hide Color;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:themed/themed.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({Key? key, required this.client}) : super(key: key);
  final Future<Client> client;
  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  late Future<String> name;
  late Future<String> username;
  bool switchValue = false;
  bool isGuest = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    return Drawer(
      backgroundColor: AppCommonTheme.backgroundColor,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          FutureBuilder<Client>(
            future: widget.client,
            builder: (BuildContext context, AsyncSnapshot<Client> snapshot) {
              if (snapshot.hasData) {
                if (snapshot.requireData.isGuest()) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 20),
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            alignment: Alignment.center,
                            backgroundColor: MaterialStateProperty.all<Color>(
                              AppCommonTheme.primaryColor,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: Text(AppLocalizations.of(context)!.login),
                        ),
                      ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            alignment: Alignment.center,
                            backgroundColor: MaterialStateProperty.all<Color>(
                              AppCommonTheme.primaryColor,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: Text(AppLocalizations.of(context)!.signUp),
                        ),
                      ),
                    ],
                  );
                } else {
                  name = snapshot.requireData.displayName();
                  username =
                      snapshot.requireData.userId().then((u) => u.toString());
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: snapshot.requireData,
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          child: CustomAvatar(
                            radius: 24,
                            avatar: snapshot.requireData.avatar(),
                            displayName: name,
                            isGroup: false,
                            stringName: '',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future:
                                  name, // a previously-obtained Future<String> or null
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<String> snapshot,
                              ) {
                                if (snapshot.hasData) {
                                  return Text(
                                    snapshot.data ??
                                        AppLocalizations.of(context)!.noName,
                                    style: SideMenuAndProfileTheme
                                        .sideMenuProfileStyle,
                                  );
                                } else {
                                  return SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppCommonTheme.primaryColor,
                                    ),
                                  );
                                }
                              },
                            ),
                            FutureBuilder<String>(
                              future:
                                  username, // a previously-obtained Future<String> or null
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<String> snapshot,
                              ) {
                                if (snapshot.hasData) {
                                  return Text(
                                    snapshot.data ?? '',
                                    style: SideMenuAndProfileTheme
                                            .sideMenuProfileStyle +
                                        FontSize(14),
                                  );
                                } else {
                                  return SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(
                                      color: AppCommonTheme.primaryColor,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              } else {
                return Container();
              }
            },
          ),
          SizedBox(
            height: _size.height * 0.04,
          ),
          SizedBox(
            height: _size.height * 0.65,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/task.svg',
                      width: 25,
                      height: 25,
                      color: Colors.teal[700],
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.toDoList,
                      style: SideMenuAndProfileTheme.sideMenuStyle,
                    ),
                    onTap: () => {},
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/gallery.svg',
                      width: 25,
                      height: 25,
                      color: Colors.teal[700],
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.gallery,
                      style: SideMenuAndProfileTheme.sideMenuStyle,
                    ),
                    onTap: () => {
                      Navigator.pushNamed(context, '/gallery'),
                    },
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/event.svg',
                      width: 25,
                      height: 25,
                      color: Colors.teal[700],
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.events,
                      style: SideMenuAndProfileTheme.sideMenuStyle,
                    ),
                    onTap: () => {},
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/shared_resources.svg',
                      width: 25,
                      height: 25,
                      color: Colors.teal[700],
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.sharedResource,
                      style: SideMenuAndProfileTheme.sideMenuStyle,
                    ),
                    onTap: () => {},
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/polls.svg',
                      width: 25,
                      height: 25,
                      color: Colors.teal[700],
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.pollsVotes,
                      style: SideMenuAndProfileTheme.sideMenuStyle,
                    ),
                    onTap: () => {},
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/group_budgeting.svg',
                      width: 25,
                      height: 25,
                      color: Colors.teal[700],
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.groupBudgeting,
                      style: SideMenuAndProfileTheme.sideMenuStyle,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SocialProfileScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/shared_documents.svg',
                      width: 25,
                      height: 25,
                      color: Colors.teal[700],
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.sharedDocuments,
                      style: SideMenuAndProfileTheme.sideMenuStyle,
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/faq.svg',
                      width: 25,
                      height: 25,
                      color: Colors.teal[700],
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.faqs,
                      style: SideMenuAndProfileTheme.sideMenuStyle,
                    ),
                    onTap: () {},
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  FutureBuilder<Client>(
                    future: widget.client,
                    builder:
                        (BuildContext context, AsyncSnapshot<Client> snapshot) {
                      if (snapshot.hasData) {
                        if (!snapshot.requireData.isGuest()) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 20, left: 10),
                            alignment: Alignment.bottomCenter,
                            child: InkWell(
                              onTap: () {},
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      child: SvgPicture.asset(
                                        'assets/images/logout.svg',
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      );
                                    },
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.logOut,
                                    style: SideMenuAndProfileTheme.signOutText,
                                  )
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Container();
                        }
                      } else {
                        return Container();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
