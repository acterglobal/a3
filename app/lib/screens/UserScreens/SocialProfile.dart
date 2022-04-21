// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/AppCommon.dart';

class SocialProfileScreen extends StatefulWidget {
  const SocialProfileScreen({Key? key}) : super(key: key);

  @override
  _SocialProfileScreenState createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: navBarTitle('Social Profile'),
        elevation: 1,
        backgroundColor: AppColors.textFieldColor,
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
        actions: [
          IconButton(
            icon: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 10),
              child: Image.asset('assets/images/edit.png'),
            ),
            onPressed: () {
              setState(() {});
            },
          )
        ],
      ),
      // drawer: SideDrawer(),
      body: Container(
        color: Colors.black,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 15, left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.textFieldColor,
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
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: AppColors.primaryColor,
                                width: 5,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                'https://dragonball.guru/wp-content/uploads/2021/01/goku-dragon-ball-guru.jpg',
                              ),
                              radius: 50,
                            ),
                          ),
                          Text(
                            'Harjeet kAUR',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Harjeet@gmail.com',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 25,
              ),
              DefaultTabController(
                length: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TabBar(
                      tabs: [
                        Tab(
                          child: Text(
                            'News',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Feed',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'More details',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      indicatorColor: AppColors.primaryColor,
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height - 100,
                      child: TabBarView(
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
      ),
    );
  }
}
