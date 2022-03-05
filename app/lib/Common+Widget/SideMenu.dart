// ignore_for_file: prefer_const_constructors

import 'package:effektio/Common+Store/Colors.dart';
import 'package:effektio/Screens/SideMenuScreens/Gallery.dart';
import 'package:effektio/Screens/UserScreens/SocialProfile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.textFieldColor,
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 70, left: 30),
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.all(10),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://dragonball.guru/wp-content/uploads/2021/01/goku-dragon-ball-guru.jpg',
                    ),
                    radius: 24,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ignore: sized_box_for_whitespace
                    Container(
                      width: 150,
                      child: Text(
                        'John Cena',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'JohnCena@gmail.com',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          SizedBox(
            height: 40,
          ),
          ListTile(
            leading: Image.asset('assets/images/task.png'),
            title: Text(
              'Todo List',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
            ),
            onTap: () => {},
          ),
          ListTile(
            leading: Image.asset('assets/images/gallery.png'),
            title: Text(
              'Gallery',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
            ),
            onTap: () => {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GalleryScreen()),
              )
            },
          ),
          ListTile(
            leading: Image.asset('assets/images/calendar.png'),
            title: Text(
              'Events',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
            ),
            onTap: () => {},
          ),
          ListTile(
            leading: Image.asset('assets/images/share.png'),
            title: Text(
              'Shared resource',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
            ),
            onTap: () => {},
          ),
          ListTile(
            leading: Image.asset('assets/images/polls.png'),
            title: Text(
              'Polls & Votes',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
            ),
            onTap: () => {},
          ),
          ListTile(
            leading: Image.asset('assets/images/people.png'),
            title: Text(
              'Group Budgeting',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SocialProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: Image.asset('assets/images/document.png'),
            title: Text(
              'Shared Documents',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Image.asset('assets/images/faq.png'),
            title: Text(
              'FAQs',
              style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white),
            ),
            onTap: () {},
          ),
          Expanded(
            child: Align(
              alignment: FractionalOffset.bottomCenter,
              child: MaterialButton(
                onPressed: () => {},
                child: Container(
                  margin: EdgeInsets.only(bottom: 50),
                  height: 100,
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        IconButton(
                          icon: Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: Image.asset('assets/images/logout.png'),
                          ),
                          onPressed: () {},
                        ),
                        Text(
                          'logout',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: AppColors.primaryColor,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
