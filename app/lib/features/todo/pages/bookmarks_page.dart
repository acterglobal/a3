import 'package:acter/common/themes/seperated_themes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
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
            Atlas.arrow_left_circle,
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
              onTap: () => buildAboutDialog(),
              child: const Icon(
                Atlas.info_circle,
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
                      style: ToDoTheme.descriptionTextStyle.copyWith(
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
                              Atlas.arrow_right_circle,
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

  Future buildAboutDialog() {
    return showDialog(
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
                        style: ToDoTheme.descriptionTextStyle,
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
