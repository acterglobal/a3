// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewsSideBar extends StatelessWidget {
  const NewsSideBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle style = Theme.of(context).textTheme.bodyText1!.copyWith(
          fontSize: 13,
          color: Colors.white,
        );
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _sideBarItem('heart', '2,8M', style),
          _sideBarItem('comment', '11,0K', style),
          _sideBarItem('reply', '76,1K', style),
          _profileImageButton(),
        ],
      ),
    );
  }

  // ignore: always_declare_return_types
  _profileImageButton() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
            ),
            borderRadius: BorderRadius.circular(25),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(
                'https://dragonball.guru/wp-content/uploads/2021/01/goku-dragon-ball-guru.jpg',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ignore: always_declare_return_types
  _sideBarItem(String iconName, String label, TextStyle style) {
    return Column(
      children: <Widget>[
        SvgPicture.asset(
          'assets/images/$iconName.svg',
          color: Colors.white,
          width: 35,
          height: 35,
        ),
        SizedBox(
          height: 5,
        ),
        Text(label, style: style),
      ],
    );
  }
}
