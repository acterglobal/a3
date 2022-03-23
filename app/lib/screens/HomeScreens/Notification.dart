// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio/common/store/Colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 5,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.textFieldColor,
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.only(top: 10, left: 15, right: 15),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      margin: EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          'https://dragonball.guru/wp-content/uploads/2021/01/goku-dragon-ball-guru.jpg',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ignore: sized_box_for_whitespace
                        Container(
                          width: MediaQuery.of(context).size.width - 150,
                          margin: EdgeInsets.only(right: 10),
                          child: Text(
                            'Lorem Ipsum is simply dummy text of the printing',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          '35 members',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
