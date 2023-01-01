import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';

class ToDoBookmarkScreen extends StatefulWidget {
  const ToDoBookmarkScreen({Key? key}) : super(key: key);

  @override
  State<ToDoBookmarkScreen> createState() => _ToDoBookmarkScreenState();
}

class _ToDoBookmarkScreenState extends State<ToDoBookmarkScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCommonTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppCommonTheme.backgroundColorLight,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: const Text(
          'Bookmarks',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => showDialogBox(),
              child: const Icon(
                FlutterIcons.exclamation_evi,
                color: Colors.white,
                size: 24,
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemBuilder: (context, index) {
            return Card(
              color: AppCommonTheme.backgroundColorLight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oct 19 at 3:36am',
                      style: ToDoTheme.subtitleTextStyle.copyWith(
                        color: ToDoTheme.calendarColor,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Web application on design',
                      style: ToDoTheme.listTitleTextStyle,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'View message',
                              style: ToDoTheme.listSubtitleTextStyle,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: ToDoTheme.secondaryTextColor,
                              size: 18,
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  showDialogBox() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: ToDoTheme.backgroundGradientColor,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            height: 250,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'About this Bookmark',
                    style: ToDoTheme.titleTextStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    'These bookmarks are only available in ToDo feature alone. They are available to your account only',
                    textAlign: TextAlign.center,
                    style: ToDoTheme.titleTextStyle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: AppCommonTheme.primaryColor,
                        borderRadius: BorderRadius.all(Radius.circular(100.0)),
                      ),
                      child: const Text(
                        'Okay',
                        style: ToDoTheme.subtitleTextStyle,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
