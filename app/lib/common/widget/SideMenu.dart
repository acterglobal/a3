// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/screens/UserScreens/SocialProfile.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({Key? key, required this.client}) : super(key: key);
  final Future<Client> client;
  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  late Future<String> name;
  late Future<String> username;
  late Future<List<int>> avatar;
  bool isGuest = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.of(context).size;
    return Drawer(
      backgroundColor: AppColors.textFieldColor,
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
              top: _size.height * 0.04,
            ),
            child: FutureBuilder<Client>(
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
                                AppColors.primaryColor,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text('Login'),
                          ),
                        ),
                        Container(
                          alignment: Alignment.bottomCenter,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              alignment: Alignment.center,
                              backgroundColor: MaterialStateProperty.all<Color>(
                                AppColors.primaryColor,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: Text('Signup'),
                          ),
                        ),
                      ],
                    );
                  } else {
                    avatar = snapshot.requireData
                        .avatar()
                        .then((fb) => fb.asTypedList());
                    name = snapshot.requireData.displayName();
                    username = snapshot.requireData.userId();
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: Row(
                        children: [
                          FutureBuilder<List<int>>(
                            future:
                                avatar, // a previously-obtained Future<String> or null
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<List<int>> snapshot,
                            ) {
                              if (snapshot.hasData) {
                                return Container(
                                  margin: EdgeInsets.all(10),
                                  child: CircleAvatar(
                                    backgroundImage: MemoryImage(
                                      Uint8List.fromList(
                                        snapshot.requireData,
                                      ),
                                    ),
                                    radius: 24,
                                  ),
                                );
                              } else {
                                return Container(
                                  margin: EdgeInsets.all(10),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.brown.shade800,
                                    child: const Text('G'),
                                    radius: 24,
                                  ),
                                );
                              }
                            },
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
                                      snapshot.data ?? 'No Name',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    );
                                  } else {
                                    return SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
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
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    );
                                  } else {
                                    return SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
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
                      'Todo List',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      'Gallery',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      'Events',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      'Shared resource',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      'Polls & Votes',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      'Group Budgeting',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      'Shared Documents',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      'FAQs',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                                    'Logout',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      color: AppColors.primaryColor,
                                    ),
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
