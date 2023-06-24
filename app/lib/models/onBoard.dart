import 'package:flutter/material.dart';

class OnBoarding extends StatefulWidget { 
  const OnBoarding({super.key, required this.image, required this.title, required this.description});

 final String image;
  final Widget title;
  final Widget description;


  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Color(0xff0A1A29),
      body: Container(
        margin: const EdgeInsets.only(top: kToolbarHeight),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                  colors: [
                    Colors.yellow,
                    Colors.orangeAccent,
                    Colors.yellow.shade300,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
       )
        ),
        child: Column(
          children: [
            Container(
              height:100,child: widget.title),
            Center(child: Image.asset(widget.image)),
            Container(height:100,child: widget.description)
          ],
        ),
      ),
    );
  }
}


