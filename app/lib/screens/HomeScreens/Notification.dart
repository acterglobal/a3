import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: NotificationTheme.notificationcardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(15, 10, 15, 0),
          child: Row(
            children: [
              Container(
                height: 60,
                width: 60,
                margin: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://dragonball.guru/wp-content/uploads/2021/01/goku-dragon-ball-guru.jpg',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 150,
                    margin: const EdgeInsets.only(right: 10),
                    child: const Text(
                      'Lorem Ipsum is simply dummy text of the printing',
                      style: NotificationTheme.titleStyle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '35 members',
                    style: NotificationTheme.subTitleStyle,
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
